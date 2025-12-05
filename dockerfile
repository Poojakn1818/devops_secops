# Multi-stage build for Go application
FROM golang:1.23-alpine AS builder

# Install git and ca-certificates (needed for go mod download)
RUN apk add --no-cache git ca-certificates

# Set working directory
WORKDIR /app

# Copy go mod files first (for better layer caching)
COPY go.mod go.sum ./

# Download dependencies with verification
RUN go mod download && go mod verify

# Copy the entire source code
COPY . .

# Build the application with optimizations
# Adjust the path to your main.go file if needed
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -a -installsuffix cgo \
    -ldflags="-w -s" \
    -o app ./cmd/

# Final stage - minimal image
FROM alpine:latest

# Install ca-certificates for HTTPS requests
RUN apk --no-cache add ca-certificates

# Create non-root user for security
RUN addgroup -g 1000 appuser && \
    adduser -D -u 1000 -G appuser appuser

WORKDIR /home/appuser

# Copy the binary from builder
COPY --from=builder /app/app .

# Change ownership to non-root user
RUN chown -R appuser:appuser /home/appuser

# Switch to non-root user
USER appuser

# Expose port (Cloud Run will set PORT env variable)
EXPOSE 8080

# Set default port environment variable
ENV PORT=8080

# Run the application
CMD ["./app"]