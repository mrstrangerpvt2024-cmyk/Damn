# Use a Python 3.12.3 Alpine base image
FROM python:3.12-alpine3.20

# Set the working directory inside the container
WORKDIR /app

# --- Phase 1: Dependencies for Caching ---

# 1. Copy only the requirements file first.
# This ensures Docker can cache the pip install layer, speeding up subsequent builds.
COPY sainibots.txt /app/

# 2. Install Python dependencies (Cachable step)
RUN pip3 install --no-cache-dir --upgrade pip \
    && pip3 install --no-cache-dir --upgrade -r sainibots.txt \
    && python3 -m pip install -U yt-dlp

# 3. Install build tools, system deps, and Bento4
# We use 'build-base' for common compile tools (gcc, make, etc.) and remove them later to shrink the image.
RUN apk add --no-cache \
    build-base \
    libffi-dev \
    musl-dev \
    ffmpeg \
    aria2 \
    cmake && \
    
    # Install Bento4, compile, copy the binary, and clean up immediately.
    echo "Installing Bento4..." && \
    wget -q https://github.com/axiomatic-systems/Bento4/archive/v1.6.0-639.zip && \
    unzip v1.6.0-639.zip && \
    cd Bento4-1.6.0-639 && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make -j$(nproc) && \
    cp mp4decrypt /usr/local/bin/ && \
    cd /app && \
    rm -rf Bento4-1.6.0-639 v1.6.0-639.zip && \
    
    # Remove temporary build packages to reduce final image size.
    apk del build-base 

# --- Phase 2: Application Code and Entrypoint ---

# 4. Copy the rest of the application code now (This layer changes most frequently).
COPY . .

# Set the command to run the application, binding gunicorn correctly for Render's environment.
CMD ["sh", "-c", "gunicorn app:app --bind 0.0.0.0:$PORT & python3 modules/main.py"]
