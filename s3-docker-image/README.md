# s3-docker-image
build an image from the file and run to create a s3 bucket.
docker build -t image_name .
to creat a s3 bucket run the command
docker run --rm -e AWS_ACCESS_KEY_ID="xxxxxx" -e AWS_SECRET_ACCESS_KEY="xxxxxxxx" image_name
