FROM python:3.12-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

COPY app/ /app/app/

RUN pip install --no-cache-dir -r /app/app/requirements.txt

EXPOSE 5000
CMD ["python", "app/app.py"]
