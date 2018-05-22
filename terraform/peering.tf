#Peering
data "aws_caller_identity" "peer" {
  provider = "aws.west"
}

# Requester's side of the connection.
resource "aws_vpc_peering_connection" "peer" {
  provider      = "aws.east"
  vpc_id        = "${module.vpc-east.vpc_id}"
  peer_vpc_id   = "${module.vpc-west.vpc_id}"
  peer_owner_id = "${data.aws_caller_identity.peer.account_id}"
  peer_region   = "us-west-2"
  auto_accept   = false

  tags {
    Side = "Requester"
  }
}

# Accepter's side of the connection.
resource "aws_vpc_peering_connection_accepter" "peer" {
  provider                  = "aws.west"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.peer.id}"
  auto_accept               = true

  tags {
    Side = "Accepter"
  }
}

#Peer public subnets
resource "aws_route" "east-west-public" {
  provider                  = "aws.east"
  route_table_id            = "${module.vpc-east.public_route_table_ids[0]}"
  destination_cidr_block    = "${module.vpc-west.vpc_cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.peer.id}"
}

resource "aws_route" "west-east-public" {
  provider                  = "aws.west"
  route_table_id            = "${module.vpc-west.public_route_table_ids[0]}"
  destination_cidr_block    = "${module.vpc-east.vpc_cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.peer.id}"
}

#Peer private subnets
resource "aws_route" "east-west-a" {
  provider                  = "aws.east"
  route_table_id            = "${module.vpc-east.private_route_table_ids[0]}"
  destination_cidr_block    = "${module.vpc-west.vpc_cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.peer.id}"
}

resource "aws_route" "east-west-b" {
  provider                  = "aws.east"
  route_table_id            = "${module.vpc-east.private_route_table_ids[1]}"
  destination_cidr_block    = "${module.vpc-west.vpc_cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.peer.id}"
}

resource "aws_route" "east-west-c" {
  provider                  = "aws.east"
  route_table_id            = "${module.vpc-east.private_route_table_ids[2]}"
  destination_cidr_block    = "${module.vpc-west.vpc_cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.peer.id}"
}

resource "aws_route" "west-east-a" {
  provider                  = "aws.west"
  route_table_id            = "${module.vpc-west.private_route_table_ids[0]}"
  destination_cidr_block    = "${module.vpc-east.vpc_cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.peer.id}"
}

resource "aws_route" "west-east-b" {
  provider                  = "aws.west"
  route_table_id            = "${module.vpc-west.private_route_table_ids[1]}"
  destination_cidr_block    = "${module.vpc-east.vpc_cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.peer.id}"
}

resource "aws_route" "west-east-c" {
  provider                  = "aws.west"
  route_table_id            = "${module.vpc-west.private_route_table_ids[2]}"
  destination_cidr_block    = "${module.vpc-east.vpc_cidr_block}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.peer.id}"
}
