FROM python:3.11-slim
ENV PYTHONUNBUFFERED=1 PIP_NO_CACHE_DIR=1
COPY install-system.py /install-system.py
RUN python /install-system.py
RUN pip install paddlepaddle==3.2.1 && pip install "paddleocr[doc-parser]==3.7.0" paddlex==3.7.2 aiohttp==3.11.18 yarl==1.20.1 && paddlex --install serving
COPY start.py /start.py
EXPOSE 8080
CMD ["python", "/start.py"]
