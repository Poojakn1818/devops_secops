# Multi-stage build for Go application
FROM golang:1.24-alpine AS builder

# Install git and ca-certificates (needed for go mod download)
RUN apk add --no-cache git ca-certificates

# Set working directory
WORKDIR /app

# Copy go mod files first (for better layer caching)
COPY go.mod ./
COPY go.sum ./

# Download dependencies
# Use go mod download with verbose output for debugging
RUN go mod download

# Copy the entire source code
COPY . .

# Build the application
# Adjust the path to your main.go file if needed
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app ./cmd/

# Final stage - minimal image
FROM alpine:latest

# Install ca-certificates for HTTPS requests
RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copy the binary from builder
COPY --from=builder /app/app .

# Expose port (adjust if your app uses a different port)
EXPOSE 8080

# Run the application
CMD ["./app"]