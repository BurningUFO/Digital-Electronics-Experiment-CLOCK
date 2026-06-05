from __future__ import annotations

from .base import BaseTransport


class SerialTransport(BaseTransport):
    def __init__(self, port: str, baudrate: int = 115200, timeout: float = 1.0) -> None:
        try:
            import serial
        except ImportError as exc:
            raise RuntimeError("pyserial is required for serial mode") from exc
        self._serial = serial.Serial(port=port, baudrate=baudrate, timeout=timeout)

    def transact(self, frame_line: str) -> str:
        self._serial.write(frame_line.encode("ascii"))
        self._serial.flush()
        response = self._serial.readline()
        if not response:
            raise TimeoutError("serial response timeout")
        return response.decode("ascii")

    def close(self) -> None:
        self._serial.close()
