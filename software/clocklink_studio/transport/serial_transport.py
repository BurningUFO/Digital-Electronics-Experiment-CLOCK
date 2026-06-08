from __future__ import annotations

import queue
import threading
import time

from protocol.codec import FrameError, decode_frame

from .base import BaseTransport


class SerialTransport(BaseTransport):
    def __init__(self, port: str, baudrate: int = 115200, timeout: float = 1.0) -> None:
        try:
            import serial
        except ImportError as exc:
            raise RuntimeError("pyserial is required for serial mode") from exc
        self._command_timeout = timeout
        self._serial = serial.Serial(port=port, baudrate=baudrate, timeout=0.1)
        self._write_lock = threading.Lock()
        self._stop = threading.Event()
        self._rx_queue: queue.Queue[str] = queue.Queue()
        self._event_queue: queue.Queue[str] = queue.Queue()
        self._reader = threading.Thread(target=self._read_loop, name="ClockLinkSerialReader", daemon=True)
        self._reader.start()

    def _read_loop(self) -> None:
        while not self._stop.is_set():
            try:
                response = self._serial.readline()
            except Exception:
                if not self._stop.is_set():
                    self._stop.set()
                return
            if response:
                self._rx_queue.put(response.decode("ascii", errors="replace"))

    def _seq_hex(self, frame_line: str) -> str | None:
        try:
            return decode_frame(frame_line).seq_hex
        except FrameError:
            return None

    def transact(self, frame_line: str) -> str:
        expected_seq = self._seq_hex(frame_line)
        deadline = time.monotonic() + self._command_timeout

        with self._write_lock:
            self._serial.write(frame_line.encode("ascii"))
            self._serial.flush()

        while time.monotonic() < deadline:
            timeout = max(0.01, min(0.05, deadline - time.monotonic()))
            try:
                response = self._rx_queue.get(timeout=timeout)
            except queue.Empty:
                continue

            if expected_seq is None or self._seq_hex(response) == expected_seq:
                return response
            self._event_queue.put(response)

        raise TimeoutError("serial response timeout")

    def poll_event(self) -> str | None:
        for source in (self._event_queue, self._rx_queue):
            try:
                return source.get_nowait()
            except queue.Empty:
                pass
        return None

    def close(self) -> None:
        self._stop.set()
        self._serial.close()
        if self._reader.is_alive():
            self._reader.join(timeout=0.3)
