from sqlalchemy import Float, String
from sqlalchemy.orm import Mapped, mapped_column

from .database import Base


class Trip(Base):
    __tablename__ = "trips"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    start: Mapped[str] = mapped_column(String, nullable=False)
    end: Mapped[str] = mapped_column(String, nullable=False)
    day: Mapped[str] = mapped_column(String, nullable=False, index=True)
    amount: Mapped[float] = mapped_column(Float, nullable=False)
    payment: Mapped[str] = mapped_column(String, nullable=False)
    commission: Mapped[float] = mapped_column(Float, nullable=False)
