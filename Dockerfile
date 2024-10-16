FROM python:3.12.0-alpine
LABEL maintainer="myappdeveloper.com"

# Ensure output is not buffered
ENV PYTHONUNBUFFERED=1

# Copy requirements files
COPY ./requirements.txt /tmp/requirements.txt
COPY ./requirements.dev.txt /tmp/requirements.dev.txt

# Copy the application code
COPY ./app /app

# Set working directory
WORKDIR /app

# Expose the port that Django will run on
EXPOSE 8000

# Set the ARG for development mode (default is false)
ARG DEV=false

# Create virtual environment and install dependencies
RUN python -m venv /py && \
    /py/bin/pip install --upgrade pip && \
    # Install PostgreSQL client and development dependencies for building psycopg2
    # - postgresql-client: Required to connect to PostgreSQL
    # - build-base, postgresql-dev, musl-dev: Required to compile Python packages like psycopg2 that depend on PostgreSQL
    # After installing the required Python packages, remove the temporary build dependencies to minimize the image size
    apk add --update --no-cache postgresql-client && \
    apk add --update --no-cache --virtual .tmp-build-deps \
        build-base postgresql-dev musl-dev && \
    /py/bin/pip install -r /tmp/requirements.txt && \
    if [ "$DEV" = "true" ]; then \
        /py/bin/pip install -r /tmp/requirements.dev.txt ; \
    fi && \
    rm -rf /tmp && \
    echo "Dev environment setup completed." && \
    apk del .tmp-build-deps && \
    adduser \
        --disabled-password \
        --no-create-home \
        django-user

# Set the PATH to include the virtual environment
ENV PATH="/py/bin:$PATH"

# Run the application as the django-user
USER django-user
