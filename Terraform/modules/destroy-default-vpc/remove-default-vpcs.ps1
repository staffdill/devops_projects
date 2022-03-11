#The goal of this script is to automate the deletion of the default vpcs within our amazon accounts for all regions they are created automatically and pose a security risk. 
#This script uses the aws CLI with the variables $aws_region, as well as $aws_profile to build a nested loop of all the default VPCs in the regions you supply it, and then takes apart the dependencies before finally deleting the VPC.
#The Script first identifies the VPCs in the account/regions based off the isDefault value being true, and will remove all components. There is a null resource module within this folder that calls the script and allows you to pass in as many regions as you would like. 

param($aws_region, $aws_profile)

Try
{
    $VPCs = $null
    $VPCs = aws ec2 describe-vpcs --filter "Name=isDefault,Values=true" --profile "$aws_profile" --region $aws_region | convertfrom-json 
    Write-Host $VPCs.vpcs -ForegroundColor Green
    
     $Script:TotalAPICalls ++
     Write-Host "Successfully gathered VPCs in account "$aws_profile"" -ForegroundColor Green
}
Catch
{
      Write-Host " Error retrieving VPCs in account "$aws_profile" - $_" -ForegroundColor Red
      break
}
foreach($VPC in $VPCs.vpcs)
{
        $VPCId = $null
        $VPCId = $VPC.VpcId 
        $VPCCIDR = $null
        $VPCCIDR = $VPC.CidrBlock
        Write-Host "Default VPC Found - $VPCId - CIDR: $VPCCIDR in Region:  $aws_region  on AWS Account: "$aws_profile"" -ForegroundColor Green

        Try
        {
            $NICs = $null
            $NICs = aws ec2 describe-network-interfaces --filters "Name=vpc-id,Values=$VPCId" --profile "$aws_profile" --region $aws_region | convertfrom-json
            $Script:TotalAPICalls ++
        }
        Catch
        {

             Write-Host " error retrieving Nics in account "$aws_profile" and region:  $aws_region - $_" -ForegroundColor Red
        }
        if($NICs)
        {
            foreach($NIC in $NICs.NICs)
            {

                $Attached = $null
                $Attached = $NIC.Attachment
                foreach($Attach in $Attached)
                {
                    $AttachId = $null
                    $AttachId = $Attach.AttachmentId
                    $NICId = $null
                    $NICId = $NIC.NetworkInterfaceId

                    aws ec2 detach-network-interface -AttachmentId $AttachId -ForceDismount:$true -Force --profile "$aws_profile" --region $aws_region

                   aws ec2 delete-network-interface -NetworkInterfaceId $NICId -Force --profile "$aws_profile" --region $aws_region
                }
            }
        }


        Try
        {
            $IGW = $null
            $IGW = aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPCId" --profile "$aws_profile" --region $aws_region | convertfrom-json
            $IGWId = $IGW.InternetGateways.InternetGatewayId
            $Script:TotalAPICalls ++
        }
        Catch
        {
             Write-Host " error retrieving IGWs in account "$aws_profile" and region:  $aws_region - $_" -ForegroundColor Red
        }
        if($IGW)
        {
            Try
            {
               aws ec2 detach-internet-gateway --internet-gateway-id $IGWId --vpc-id $VPCId --profile "$aws_profile" --region $aws_region
                $Script:TotalAPICalls ++
                Write-Host " dismounting internet gateway $IGW from VPC $VPCId in region $aws_region and account "$aws_profile" - $_" -ForegroundColor Green
            }
            Catch
            {
                 Write-Host " error dismounting internet gateway $IGW from VPC $VPCId in region $aws_region and account "$aws_profile" - $_" -ForegroundColor Red
            }

            Try
            {
                aws ec2 delete-internet-gateway --internet-gateway-id $IGWId --profile "$aws_profile" --region $aws_region
                $Script:TotalAPICalls ++
                Write-Host " deleting internet gateway $IGW from VPC $VPCId in region $aws_region and account "$aws_profile" - $_" -ForegroundColor Green
            }
            Catch
            {
                 Write-Host " error deleting internet gateway $IGW from VPC $VPCId in region $aws_region and account "$aws_profile" - $_" -ForegroundColor Red
            }

        }

        Try
            {

                 $RouteTables = $null
                 $RouteTables = aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPCId" --profile "$aws_profile" --region $aws_region | convertfrom-json
                 $Script:TotalAPICalls ++
                 foreach($RouteTable in $RouteTables)
                 {
                     $RouteTableIds = $null
                     $RouteTableAssociations = $null
                     $RouteTableIds = $RouteTables.RouteTables.RouteTableId
                     $RouteTableAssociations = $RouteTables.RouteTables.Associations.RouteTableAssociationId

                     foreach($RTBAssoc in $RouteTableAssociations)
                            {

                                if ($RTBAssoc.Main)
                                {
                                             ######### don't touch the main route table
                                    Write-Output ""$aws_profile"; "$aws_profile"Name; $aws_region; $DefaultVPC; main route table $RouteTableId"
                                }
                                else
                                {
                                    $RTBAssocId = $RTBAssoc.RouteTableAssociationId
                                    #Write-Output ""$aws_profile"; "$aws_profile"Name; $aws_region; $DefaultVPC; route table to delete $RouteTableId; $RTBAssocId"

                                     ######### let's unregister the route table to prepare to delete it
                                    Write-Output ""$aws_profile"; "$aws_profile"Name; $aws_region; $DefaultVPC; detaching route table $RouteTableId; $RTBAssocId"

                                    try
                                    {
                                        $RTBUnregister = aws ec2 disassociate-route-table --association-id $RTBAssocId --profile "$aws_profile" --region $aws_region
                                    }

                                    catch
                                    {
                                        $Failures = "Yes"
                                        Write-Output ""$aws_profile"; "$aws_profile"Name; $aws_region; ERROR ERROR ERROR on GET-EC2Instance"
                                        $ErrorMessage = $_.Exception.Message
                                        $FailedItem = $_.Exception.ItemName
                                        Write-Output "`n $ErrorMessage "
                                        Write-Output "`n $FailedItem "
                                    }

                                    Write-Output ""$aws_profile"; "$aws_profile"Name; $aws_region; $DefaultVPC; route table detached $RouteTableId; $RTBAssocId"


                                    ######### now time to delete the route table
                                    Write-Output ""$aws_profile"; "$aws_profile"Name; $aws_region; $DefaultVPC; deleting route table $RouteTableId; $RTBAssocId"

                                    try
                                    {
                                        $RTBDelete = aws ec2 delete-route-table --route-table-id $RouteTableIds --profile "$aws_profile" --region $aws_region
                                    }

                                    catch
                                    {
                                        $Failures = "Yes"
                                        Write-Output ""$aws_profile"; "$aws_profile"Name; $aws_region; failed on Remove-EC2RouteTable"
                                        $ErrorMessage = $_.Exception.Message
                                        $FailedItem = $_.Exception.ItemName
                                        Write-Output "`n $ErrorMessage "
                                        Write-Output "`n $FailedItem "
                                    }

                                    Write-Output ""$aws_profile"; "$aws_profile"Name; $aws_region; $DefaultVPC; deleted route table $RouteTableId; $RTBAssocId"

                                }
                            }

               



                    }
            }
            Catch
            {
                Write-Host "error retrieving routetable information" -ForegroundColor Red
            }

        Try
          {
                $SubnetObjects = $null
                $SubnetObjects = aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPCId" --profile "$aws_profile" --region $aws_region | convertfrom-json
                $SubnetIds = $SubnetObjects.Subnets.SubnetId
                $Script:TotalAPICalls ++
                foreach($SubnetId in $SubnetIds)
                {
                    Try
                    {
                       aws ec2 delete-subnet --subnet-id $SubnetId --profile "$aws_profile" --region $aws_region
                        $Script:TotalAPICalls ++
                        Write-Host "  removing subnet $SubnetId from VPC $VPCId in region $aws_region and account "$aws_profile" - $_" -ForegroundColor Green
                    }
                    Catch
                    {
                         Write-Host " error deleting subnet from VPC $VPCId in region $aws_region and account "$aws_profile" - $_" -ForegroundColor Red
                    }
                }
          } 
        Catch
          {
                 Write-Host " error retrieving subnet from VPC $VPCId in region $aws_region and account "$aws_profile" - $_" -ForegroundColor Red
            }
            

            Try
            {
                 $NACLs = $null
                 $NACLs = aws ec2 describe-network-acls -Filter @{Name="vpc-id"; Values="$VPCId"} --profile "$aws_profile" --region $aws_region
                 $Script:TotalAPICalls ++   
            }
            Catch
            {
                 Write-Host " error retrieving NACLs from VPC $VPCId in region $aws_region and account "$aws_profile" - $_" -ForegroundColor Red
            }

            foreach($NACL in $NACLs)
            {
                $NACLId =$null
                $NACLId = $NACL.NetworkAclId

                if($NACLId)
                {

                    Try
                    {
                         aws ec2 delete-network-acl -NetworkAclId $NACLId  --profile "$aws_profile" --region $aws_region -ErrorAction Stop -Force
                         $Script:TotalAPICalls ++
                         Write-Host " deleting NACL $NACLId from VPC $VPCId in region $aws_region and account "$aws_profile" - $_" -ForegroundColor Green
                    }
                    Catch
                    {
                         Write-Host " error removing NACL $NACLId from VPC $VPCId in region $aws_region and account "$aws_profile" - $_" -ForegroundColor Red
                    }

                }
            }

            $SecurityGroups = aws ec2 describe-security-groups --filter "Name=vpc-id,Values=$VPCid"  --profile "$aws_profile" --region $aws_region | convertfrom-json

            foreach($SecurityGroup in $SecurityGroups.SecurityGroups)
            {
                Try
                    {
                        $SecurityGroupId = $null
                        $SecurityGroupId = $SecurityGroups.SecurityGroups.GroupId
                        aws ec2 delete-security-group --group-id $SecurityGroupId  --region $aws_region --profile "$aws_profile"
                        $Script:TotalAPICalls ++
                        Write-Host " deleting security groups $SecurityGroupId from VPC $VPCId in region $aws_region and account "$aws_profile" - $_" -ForegroundColor Green
                    }
                Catch
                {
                     Write-Host " error deleting security groups from VPC $VPCId in region $aws_region and account "$aws_profile" - $_" -ForegroundColor Red
                }
            }

            Try
            {
                 aws ec2 delete-vpc --vpc-id $VPCId  --profile "$aws_profile" --region $aws_region
                 $Script:TotalAPICalls ++
                 Write-Host " deleting VPC $VPCId in region $aws_region and account "$aws_profile" - $_" -ForegroundColor Green

            }
            Catch
            {
                 Write-Host " failed to delete VPC $VPCId in region $aws_region and account "$aws_profile" - $_" -ForegroundColor Red
            }
}