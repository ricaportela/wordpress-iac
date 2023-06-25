#!/bin/bash

# Obtém a lista de regiões disponíveis
regions=$(aws ec2 describe-regions --output text | cut -f4)

# Loop pelas regiões
for region in $regions; do
  echo "Removendo VPCs, subnets, IGWs, RTBs e ACLs na região $region"

  # Obtém a lista de VPCs
  vpcs=$(aws ec2 describe-vpcs --region $region --filters "Name=isDefault,Values=true" --query 'Vpcs[*].VpcId' --output text)

  # Loop pelas VPCs e exclui cada uma delas
  for vpc in $vpcs; do
    echo "Removendo VPC $vpc"

    # Obtém o Security Group associado à VPC
    security_group=$(aws ec2 describe-security-groups --region $region --filters "Name=vpc-id,Values=$vpc" --query 'SecurityGroups[*].GroupId' --output text)

    # Exclui o Security Group
    if [ -n "$security_group" ]; then
      echo "Removendo Security Group $security_group"
      aws ec2 delete-security-group --region $region --group-id $security_group
    fi

    # Obtém a lista de Network ACLs
    network_acls=$(aws ec2 describe-network-acls --region $region --filters "Name=vpc-id,Values=$vpc" --query 'NetworkAcls[*].NetworkAclId' --output text)

    # Loop pelas Network ACLs e exclui cada uma delas
    for acl in $network_acls; do
      echo "Removendo Network ACL $acl"
      aws ec2 delete-network-acl --region $region --network-acl-id $acl
    done

    # Obtém a lista de subnets
    subnets=$(aws ec2 describe-subnets --region $region --filters "Name=vpc-id,Values=$vpc" --query 'Subnets[*].SubnetId' --output text)

    # Loop pelas subnets e exclui cada uma delas
    for subnet in $subnets; do
      echo "Removendo subnet $subnet"
      aws ec2 delete-subnet --region $region --subnet-id $subnet
    done

    # Obtém a lista de Route Tables
    route_tables=$(aws ec2 describe-route-tables --region $region --filters "Name=vpc-id,Values=$vpc" --query 'RouteTables[*].RouteTableId' --output text)

    # Loop pelas Route Tables e exclui cada uma delas
    for rtb in $route_tables; do
      echo "Removendo Route Table $rtb"

      # Desanexa todas as subnets da Route Table
      subnets_in_rtb=$(aws ec2 describe-route-tables --region $region --route-table-ids $rtb --query 'RouteTables[*].Associations[?SubnetId!=`null`].SubnetId' --output text)
      for subnet in $subnets_in_rtb; do
        echo "Desanexando subnet $subnet da Route Table $rtb"
        aws ec2 disassociate-route-table --region $region --association-id $subnet
      done

      # Exclui a Route Table
      aws ec2 delete-route-table --region $region --route-table-id $rtb
    done

    # Obtém o Internet Gateway associado à VPC
    igw=$(aws ec2 describe-internet-gateways --region $region --filters "Name=attachment.vpc-id,Values=$vpc" --query 'InternetGateways[*].InternetGatewayId' --output text)

    # Desanexa e exclui o Internet Gateway
    if [ -n "$igw" ]; then
      echo "Desanexando e excluindo o Internet Gateway $igw"
      aws ec2 detach-internet-gateway --region $region --internet-gateway-id $igw --vpc-id $vpc
      aws ec2 delete-internet-gateway --region $region --internet-gateway-id $igw
    fi

    # Obtém o Egress Only Internet Gateway associado à VPC
    eigw=$(aws ec2 describe-egress-only-internet-gateways --region $region --filters "Name=attachment.vpc-id,Values=$vpc" --query 'EgressOnlyInternetGateways[*].EgressOnlyInternetGatewayId' --output text)

    # Desanexa e exclui o Egress Only Internet Gateway
    if [ -n "$eigw" ]; then
      echo "Desanexando e excluindo o Egress Only Internet Gateway $eigw"
      aws ec2 delete-egress-only-internet-gateway --region $region --egress-only-internet-gateway-id $eigw
    fi

    # Exclui a VPC
    aws ec2 delete-vpc --region $region --vpc-id $vpc
  done
done
