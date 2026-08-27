from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from app.models import TaskStatus


class TaskBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    description: str = Field(default="", max_length=5000)
    status: TaskStatus = TaskStatus.NEW


class TaskCreate(TaskBase):
    pass


class TaskUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=200)
    description: str | None = Field(default=None, max_length=5000)
    status: TaskStatus | None = None


class TaskRead(TaskBase):
    id: int
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class TaskStatusUpdate(BaseModel):
    status: TaskStatus
