resource "aws_instance" "example" {
  ami           = "ami-4fffc834"
  instance_type = "t2.micro"

  tags {
    Name = "terraform-example"
  }
}
