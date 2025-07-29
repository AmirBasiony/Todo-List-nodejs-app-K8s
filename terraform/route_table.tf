###############################
#        ROUTE TABLES        #
###############################
resource "aws_route_table" "public_rt_K8s" {
  vpc_id = aws_vpc.AppVPC_K8s.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.AppInternetGateway_K8s.id
  }

  tags = {
    Name = "AppRouteTable_K8s"
  }
}

# Associating the public subnet with the public route table 
resource "aws_route_table_association" "public_assoc_K8s" {
  subnet_id      = aws_subnet.public_subnet_K8s.id
  route_table_id = aws_route_table.public_rt_K8s.id
}