FROM python:3.10-slim AS builder

# 安装系统依赖
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    cmake \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# RUN git config --global http.proxy http://myproxy:7890
# RUN git config --global https.proxy http://myproxy:7890
RUN git clone --depth 1 https://github.com/ggml-org/llama.cpp.git /llama.cpp

WORKDIR /llama.cpp

RUN mkdir build && \
    cd build && \
    cmake .. \
      -DLLAMA_CUBLAS=OFF \
      -DLLAMA_CURL=OFF \
      -DLLAMA_OPENBLAS=OFF \
      -DLLAMA_METAL=OFF \
      -DBUILD_SHARED_LIBS=OFF && \
    cmake --build . --config Release -j $(nproc)

# 运行时阶段
FROM python:3.10-slim

RUN pip install --no-cache-dir \
    numpy \
    torch \
    transformers \
    sentencepiece \
    gguf \
    -i https://pypi.tuna.tsinghua.edu.cn/simple \
    --extra-index-url https://download.pytorch.org/whl/cpu

# 设置工作目录
WORKDIR /app

COPY --from=builder /llama.cpp /app
RUN rm -rf /app/build

ENTRYPOINT ["bash", "-c", "if [ \"$DEBUG\" = \"true\" ]; then exec bash; else exec python convert_hf_to_gguf.py \"$@\"; fi", "--"]
CMD ["--help"]
