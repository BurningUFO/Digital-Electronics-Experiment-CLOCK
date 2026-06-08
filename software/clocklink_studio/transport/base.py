from abc import ABC, abstractmethod


class BaseTransport(ABC):
    @abstractmethod
    def transact(self, frame_line: str) -> str:
        raise NotImplementedError

    def poll_event(self) -> str | None:
        return None

    def close(self) -> None:
        return None
