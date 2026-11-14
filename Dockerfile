FROM python:3.12-slim

# netcat sirf troubleshooting ke liye (port check karne ke kaam aata hai)
RUN apt-get update && apt-get install -y --no-install-recommends netcat-openbsd && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ .

# clientvol yahan mount hoga
RUN mkdir -p /clientdata
VOLUME /clientdata

CMD ["python", "-u", "client.py"]
