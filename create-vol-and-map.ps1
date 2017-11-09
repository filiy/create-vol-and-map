#get variables in

$volname = Read-host -prompt "enter vol name"
$aggr = Read-host -prompt "aggregate"
$size = Read-host -prompt "enter vol size"
$dedupe = Read-host -prompt "enter vol dedupe policy"
$autgrowsize = Read-host "enter max autogrow size"
$lif = read-host "enter IP of node lif for mounting on esxi host"

$ans = Read-host -prompt "is this a DRE VM volume/datastore? yes or no"
if ($ans -eq "yes") {
	$exportpol = "All_Build_Clusters"
	$snappol =  "none"
	$location = "Build*"
	}
else {
	$exportpol = Read-host -prompt "enter vol export policy"
	$snappol = Read-host -prompt "enter vol snapshot policy"
	$location = read-host "enter esxi hosts location e.g.; EAC Cluster 1"
	}

#load up the netapp ontap powershell module
import-module dataontap

#connect to the cluster
connect-nccontroller -name eac-cluster1

#create the vol and set autosize settings
New-NcVol -Name $volname -Aggregate $aggr -JunctionPath /$volname -ExportPolicy $exportpol -SnapshotPolicy $snappol -Size $size -SpaceReserve none -SnapshotReserve 0 -vservercontext eac-vm1 -EfficiencyPolicy $dedupe
get-ncvol -name $volname | set-ncvolautosize -mode grow -GrowThresholdPercent 94 -incrementsize 200g -maximumsize $autgrowsize
Get-NcVol $volname | Set-NcVolOption -Key no_atime_update -Value on

#load up the vmware powercli module 
. "C:\Program Files (x86)\VMware\Infrastructure\vSphere PowerCLI\Scripts\Initialize-PowerCLIEnvironment.ps1"

#connect to vcetner
connect-viserver eac-vcenter

$servers = Get-VMHost  -Location $location

foreach ($serv in $servers) {
	New-Datastore -Nfs -VMHost $serv.name -name $volname -path /$volname -NfsHost $lif
}