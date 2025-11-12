# Use a Python 3.12.3 Alpine base image 
FROM python:3.12-alpine3.20

# Set working directory
WORKDIR /app

# --- Phase 1: System deps and Python dependencies ---

# Install build tools, libffi, musl-dev for TgCrypto
RUN apk add --no-cache \
    build-base \
    libffi-dev \
    musl-dev \
    wget \
    unzip \
    ffmpeg \
    aria2 \
    cmake \
    python3-dev

# Copy requirements
COPY sainibots.txt /app/

# Install Python dependencies
RUN pip3 install --no-cache-dir --upgrade pip \
    && pip3 install --no-cache-dir --upgrade -r sainibots.txt \
    && python3 -m pip install -U yt-dlp

# Install Bento4
RUN echo "Installing Bento4..." && \
    wget -q https://github.com/axiomatic-systems/Bento4/archive/v1.6.0-639.zip && \
    unzip v1.6.0-639.zip && \
    cd Bento4-1.6.0-639 && \
    mkdir build && cd build && \
    cmake .. && make -j$(nproc) && \
    cp mp4decrypt /usr/local/bin/ && \
    cd /app && \
    rm -rf Bento4-1.6.0-639 v1.6.0-639.zip

# Remove build packages to reduce image size
RUN apk del build-base musl-dev python3-dev cmake unzip wget

# --- Phase 2: Application code ---

COPY . .

# CMD to run app
CMD ["sh", "-c", "gunicorn app:app --bind 0.0.0.0:$PORT & python3 modules/main.py"]
