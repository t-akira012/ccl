# terraform-security-group-public-private

**User**:
セキュリティグループのterraformリソースを作れ。埋め込み型にしろ。

以下の設定とする。

${var.prefix}-prv-sg
${var.prefix}-pub-sg

作るのはこれだけだ。

pubはインターネット外からの通信を許可する。
prvはインターネット外からの通信を許可せず、pubからの通信に限り許可する。

**Claude**:
以下のセキュリティグループのTerraformリソースを作成します：

```hcl
# パブリックセキュリティグループ
resource "aws_security_group" "pub" {
  name        = "${var.prefix}-pub-sg"
  description = "Public security group - allows internet access"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-pub-sg"
  }
}

# プライベートセキュリティグループ
resource "aws_security_group" "prv" {
  name        = "${var.prefix}-prv-sg"
  description = "Private security group - only allows from public sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.pub.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-prv-sg"
  }
}
```

