# PaddleOCR-VL-1.6 in Docker (CPU)

From this directory, in PowerShell:

```powershell
$ocrRoot = (Get-Location).Path
docker run --rm -v "${ocrRoot}:/work:ro" -v emsidrive-paddle-model:/models python:3.11-slim python /work/download-model.py
docker run --rm -v "${ocrRoot}:/work:ro" -v emsidrive-paddle-model:/models python:3.11-slim python /work/shard-model.py
docker compose up --build -d
docker compose logs -f paddleocr
```

Docker Desktop must use Linux containers. Downloading requires internet access.
Weights persist in Docker volumes. Sharding copies each tensor byte-for-byte;
it keeps the full model and avoids loading a second complete weight copy in RAM.
The startup adapter supports these shards in PaddleX 3.7.2 and verifies complete
weight coverage. It uses eight CPU threads by default. No paid API key is required.
CPU inference is slow and requires several GB of available Docker memory.

The document parsing API listens at http://localhost:8090/layout-parsing.
POST JSON with `file` containing base64 document bytes and `fileType` equal to
1 for images or 0 for PDFs. Responses contain `result.layoutParsingResults`.
This is document extraction, not EMSIDrive's final timetable JSON.

Backend integration is implemented and timing-parser tests pass. The full model starts successfully.
Real-photo timing accuracy is still being tested. To enable it for a backend
running on the host, set PADDLE_OCR_URL=http://localhost:8090/layout-parsing before
starting Spring Boot. For a containerized backend, use the Docker service hostname
on a shared network instead of localhost. No cloud fallback is used when Paddle
is selected. Restart the backend after changing configuration.

Only weekday/start/end are retained; course and room names are discarded.
Merged table cells span the first header start through the last header end.
Times printed inside a lesson override headers. Empty cells and breaks are skipped.
Header times must be visible: the six usual EMSI times are never assumed.
Crop photos to one timetable. Multiple readable tables are rejected rather than
mixing classes. Occlusion, glare, and unfamiliar layouts require manual review.
These rules do not guarantee support for every possible timetable layout.

The port is bound to localhost intentionally. The phone should communicate with
the authenticated EMSIDrive backend, not this unauthenticated model service.
Stop with `docker compose down`; avoid `down -v` to retain downloaded models.

Reference: https://www.paddleocr.ai/main/en/version3.x/pipeline_usage/PaddleOCR-VL.html
