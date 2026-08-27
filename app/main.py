from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import Depends, FastAPI, Form, HTTPException, Request, status
from fastapi.responses import RedirectResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from sqlalchemy.orm import Session

from app import crud, schemas
from app.config import settings
from app.database import Base, engine, get_db
from app.models import TaskStatus

BASE_DIR = Path(__file__).resolve().parent.parent
templates = Jinja2Templates(directory=str(BASE_DIR / "templates"))


@asynccontextmanager
async def lifespan(_: FastAPI):
    Base.metadata.create_all(bind=engine)
    yield


app = FastAPI(title=settings.app_name, lifespan=lifespan)
app.mount("/static", StaticFiles(directory=str(BASE_DIR / "static")), name="static")


def redirect_to_home() -> RedirectResponse:
    return RedirectResponse(url="/", status_code=status.HTTP_303_SEE_OTHER)


@app.get("/", include_in_schema=False)
def home(request: Request, db: Session = Depends(get_db)):
    tasks = crud.get_tasks(db)
    return templates.TemplateResponse(
        request,
        "index.html",
        {
            "tasks": tasks,
            "statuses": [status.value for status in TaskStatus],
            "task_status": TaskStatus,
        },
    )


@app.post("/tasks", include_in_schema=False)
def create_task_from_form(
    title: str = Form(...),
    description: str = Form(""),
    db: Session = Depends(get_db),
):
    crud.create_task(
        db,
        schemas.TaskCreate(title=title.strip(), description=description.strip()),
    )
    return redirect_to_home()


@app.get("/tasks/{task_id}/edit", include_in_schema=False)
def edit_task_page(task_id: int, request: Request, db: Session = Depends(get_db)):
    task = crud.get_task(db, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    return templates.TemplateResponse(
        request,
        "edit.html",
        {
            "task": task,
            "statuses": [status.value for status in TaskStatus],
        },
    )


@app.post("/tasks/{task_id}/edit", include_in_schema=False)
def update_task_from_form(
    task_id: int,
    title: str = Form(...),
    description: str = Form(""),
    status_value: TaskStatus = Form(..., alias="status"),
    db: Session = Depends(get_db),
):
    task = crud.get_task(db, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    crud.update_task(
        db,
        task,
        schemas.TaskUpdate(
            title=title.strip(),
            description=description.strip(),
            status=status_value,
        ),
    )
    return redirect_to_home()


@app.post("/tasks/{task_id}/status", include_in_schema=False)
def update_status_from_form(
    task_id: int,
    status_value: TaskStatus = Form(..., alias="status"),
    db: Session = Depends(get_db),
):
    task = crud.get_task(db, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    crud.update_task(db, task, schemas.TaskUpdate(status=status_value))
    return redirect_to_home()


@app.post("/tasks/{task_id}/delete", include_in_schema=False)
def delete_task_from_form(task_id: int, db: Session = Depends(get_db)):
    task = crud.get_task(db, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    crud.delete_task(db, task)
    return redirect_to_home()


@app.get("/api/health")
def healthcheck():
    return {"status": "ok", "service": settings.app_name}


@app.get("/api/tasks", response_model=list[schemas.TaskRead])
def api_list_tasks(db: Session = Depends(get_db)):
    return crud.get_tasks(db)


@app.get("/api/tasks/{task_id}", response_model=schemas.TaskRead)
def api_get_task(task_id: int, db: Session = Depends(get_db)):
    task = crud.get_task(db, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    return task


@app.post("/api/tasks", response_model=schemas.TaskRead, status_code=status.HTTP_201_CREATED)
def api_create_task(task_in: schemas.TaskCreate, db: Session = Depends(get_db)):
    return crud.create_task(db, task_in)


@app.put("/api/tasks/{task_id}", response_model=schemas.TaskRead)
def api_update_task(task_id: int, task_in: schemas.TaskUpdate, db: Session = Depends(get_db)):
    task = crud.get_task(db, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    return crud.update_task(db, task, task_in)


@app.patch("/api/tasks/{task_id}/status", response_model=schemas.TaskRead)
def api_update_task_status(
    task_id: int,
    status_in: schemas.TaskStatusUpdate,
    db: Session = Depends(get_db),
):
    task = crud.get_task(db, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    return crud.update_task(db, task, schemas.TaskUpdate(status=status_in.status))


@app.delete("/api/tasks/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
def api_delete_task(task_id: int, db: Session = Depends(get_db)):
    task = crud.get_task(db, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    crud.delete_task(db, task)
