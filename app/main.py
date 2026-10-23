import os
import secrets
import string
from datetime import datetime, timezone
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.staticfiles import StaticFiles
from fastapi.openapi.docs import get_swagger_ui_html
from pydantic import BaseModel, HttpUrl, Field
from sqlalchemy import create_engine, String, Integer, DateTime, select
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, Session

VERSION = os.getenv("APP_VERSION", "1.0.0")
COLOR = os.getenv("APP_COLOR", "blue").lower()
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./urlshortener.db")
IS_SQLITE = DATABASE_URL.startswith("sqlite")
connect_args = {"check_same_thread": False} if IS_SQLITE else {}
engine = create_engine(DATABASE_URL, connect_args=connect_args, pool_pre_ping=True)

class Base(DeclarativeBase):
    pass

class Link(Base):
    __tablename__ = "links"
    code: Mapped[str] = mapped_column(String(16), primary_key=True)
    original_url: Mapped[str] = mapped_column(String(2048), nullable=False)
    clicks: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

@asynccontextmanager
async def lifespan(app: FastAPI):
    with engine.begin() as connection:
        Base.metadata.create_all(connection)
    yield
    
V1 = COLOR != "green"
API_TITLE = "URL Shortener API" if V1 else "Smart URL Manager API"
API_DESCRIPTION = (
    "Blue release: create short links and inspect basic click counts."
    if V1 else
    "Green release: create managed links, inspect link details, and view enhanced analytics."
)
app = FastAPI(
    title=API_TITLE,
    description=API_DESCRIPTION,
    version=VERSION,
    docs_url=None,
    redoc_url=None,
    openapi_url="/openapi.json",
    lifespan=lifespan,
)
app.mount("/static", StaticFiles(directory="app/static"), name="static")

class ShortenRequest(BaseModel):
    url: HttpUrl = Field(description="The original destination URL")

class ShortenResponse(BaseModel):
    short_code: str
    short_url: str
    original_url: str
    version: str

def new_code(length: int = 6) -> str:
    alphabet = string.ascii_letters + string.digits
    return "".join(secrets.choice(alphabet) for _ in range(length))

def base_url(request: Request) -> str:
    return str(request.base_url).rstrip("/")

@app.get("/", response_class=HTMLResponse, include_in_schema=False)
def home():
    page = "index_v1.html" if V1 else "index_v2.html"
    with open(f"app/templates/{page}", encoding="utf-8") as f:
        return f.read()

@app.get("/health", tags=["Operations"], summary="Health and deployment version")
def health():
    return {"status": "healthy", "version": VERSION, "color": COLOR}

@app.get("/docs", include_in_schema=False)
def custom_docs():
    css = "/static/swagger-blue.css" if V1 else "/static/swagger-green.css"

    response = get_swagger_ui_html(
        openapi_url=app.openapi_url,
        title=f"{API_TITLE} — Swagger",
        swagger_ui_parameters={
            "displayRequestDuration": True,
            "docExpansion": "list",
        },
    )

    html = response.body.decode("utf-8")
    html = html.replace(
        "</head>",
        f'<link rel="stylesheet" href="{css}"></head>',
    )

    return HTMLResponse(content=html)


@app.post("/shorten", response_model=ShortenResponse, tags=["Links"], summary="Create a short URL")
def shorten(payload: ShortenRequest, request: Request):
    with Session(engine) as db:
        for _ in range(8):
            code = new_code()
            if db.get(Link, code) is None:
                link = Link(code=code, original_url=str(payload.url), clicks=0)
                db.add(link)
                db.commit()
                return ShortenResponse(short_code=code, short_url=f"{base_url(request)}/{code}",
                                       original_url=link.original_url, version=VERSION)
    raise HTTPException(status_code=503, detail="Could not allocate a short code; retry.")

@app.get("/stats/{short_code}", tags=["Analytics"], summary="Get click count")
def stats(short_code: str):
    with Session(engine) as db:
        link = db.get(Link, short_code)
        if not link:
            raise HTTPException(status_code=404, detail="Short link not found")
        return {"short_code": link.code, "original_url": link.original_url,
                "clicks": link.clicks, "version": VERSION}

@app.get("/api/v2/links/{short_code}", tags=["V2 · Link management"], summary="Get full link details")
def link_details(short_code: str):
    if V1:
        raise HTTPException(status_code=404, detail="This endpoint is available in v2.")
    with Session(engine) as db:
        link = db.get(Link, short_code)
        if not link:
            raise HTTPException(status_code=404, detail="Short link not found")
        return {"short_code": link.code, "original_url": link.original_url,
                "clicks": link.clicks, "created_at": link.created_at.isoformat(),
                "version": VERSION, "deployment": COLOR}

@app.get("/api/v2/analytics/{short_code}", tags=["V2 · Analytics"], summary="Enhanced link analytics")
def enhanced_analytics(short_code: str):
    if V1:
        raise HTTPException(status_code=404, detail="This endpoint is available in v2.")
    with Session(engine) as db:
        link = db.get(Link, short_code)
        if not link:
            raise HTTPException(status_code=404, detail="Short link not found")
        return {"short_code": link.code, "total_clicks": link.clicks,
                "created_at": link.created_at.isoformat(), "version": VERSION,
                "deployment": COLOR}

@app.get("/{short_code}", include_in_schema=False)
def redirect_short(short_code: str):
    if short_code in {"favicon.ico", "robots.txt"}:
        raise HTTPException(status_code=404, detail="Not found")
    with Session(engine) as db:
        link = db.get(Link, short_code)
        if not link:
            raise HTTPException(status_code=404, detail="Short link not found")
        link.clicks += 1
        db.commit()
        return RedirectResponse(link.original_url, status_code=307)
