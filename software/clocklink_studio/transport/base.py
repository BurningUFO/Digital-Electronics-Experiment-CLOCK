from abc import ABC, abstractmethod


class BaseTransport(ABC):
    @abstractmethod
    def transact(self, frame_line: str) -> str:
        raise NotImplementedError

    def close(self) -> None:
        return None
