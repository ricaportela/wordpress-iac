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
    
    # Obtém o Internet Gateway associado à VPC
    igw=$(aws ec2 describe-internet-gateways --region $region --filters "Name=attachment.vpc-id,Values=$vpc" --query 'InternetGateways[*].InternetGatewayId' --output text)

    # Desanexa e exclui o Internet Gateway
    if [ -n "$igw" ]; then
      echo "Desanexando e excluindo o Internet Gateway $igw"
      aws ec2 detach-internet-gateway --region $region --internet-gateway-id $igw --vpc-id $vpc
      aws ec2 delete-internet-gateway --region $region --internet-gateway-id $igw
    fi
    
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
    
    # Obtém a Default Network ACL da VPC
    acl=$(aws ec2 describe-network-acls --region $region --filters "Name=vpc-id,Values=$vpc" "Name=isDefault,Values=true" --query 'NetworkAcls[*].NetworkAclId' --output text)

    # Exclui a Default Network ACL
    if [ -n "$acl" ]; then
      echo "Removendo ACL $acl"
      aws ec2 delete-network-acl --region $region --network-acl-id $acl
    fi

    # Exclui a VPC
    aws ec2 delete-vpc --region $region --vpc-id $vpc
  done
done
