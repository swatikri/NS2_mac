# ======================================================================
# Project parameters
# ======================================================================
set val(node_num)       11 
set val(duration)       10
set val(packetsize)     16
set val(repeatTx)       10
set val(interval)       0.02
set val(dimx)           50
set val(dimy)           50
set val(trace_file)     se_pa3_9.tr
set val(stats_file)     se_pa3.stats
set val(node_size)      5

# ======================================================================
# Node options
# ======================================================================
set val(chan)           Channel/WirelessChannel    ;# channel type
set val(prop)           Propagation/TwoRayGround   ;# radio-propagation model
set val(netif)          Phy/WirelessPhy            ;# network interface type
set val(mac)            Mac/ESMAC                 ;# MAC type
#set val(mac)            Mac/802_11                 ;# MAC type
set val(ifq)            Queue/DropTail/PriQueue    ;# interface queue type
set val(ll)             LL                         ;# link layer type
set val(ant)            Antenna/OmniAntenna        ;# antenna model
set val(ifqlen)         50                         ;# max packet in ifq
set val(nn)             $val(node_num)                          ;# number of mobilenodes
set val(rp)             DumbAgent                       ;# routing protocol

# ======================================================================
# Global variables
# ======================================================================
set ns                      [new Simulator]
set tracefd                 [open $val(trace_file) w]
set stats                   [open $val(stats_file) w]
#$ns namtrace-all-wireless   $nam $val(dimx) $val(dimy)
$ns trace-all               $tracefd
set topo                    [new Topography]
$topo load_flatgrid         $val(dimx) $val(dimy)

#
# Create God
#
create-god $val(nn)

Mac/ESMAC set repeatTx_ $val(repeatTx)
Mac/ESMAC set interval_ $val(interval)

$ns node-config \
        -adhocRouting $val(rp) \
        -llType $val(ll) \
        -macType $val(mac) \
        -ifqType $val(ifq) \
        -ifqLen $val(ifqlen) \
        -antType $val(ant) \
        -propType $val(prop) \
        -phyType $val(netif) \
        -channelType $val(chan) \
        -topoInstance $topo \
        -agentTrace OFF \
        -routerTrace OFF \
        -macTrace ON \
        -movementTrace OFF 
#
# The only sink node
#
set sink_node [$ns node]
$sink_node random-motion 0
$sink_node set X_ [expr $val(dimx)/2]
$sink_node set Y_ [expr $val(dimy)/2]
$sink_node set Z_ 0
$ns initial_node_pos $sink_node $val(node_size)

set sink [new Agent/LossMonitor]
$ns attach-agent $sink_node $sink

#
# Set up random number generator, to scatter the source nodes
#
set rng [new RNG]
$rng seed 0

set xrand [new RandomVariable/Uniform]
$xrand use-rng $rng
$xrand set min_ [expr -$val(dimx)/2]
$xrand set max_ [expr $val(dimx)/2]

set yrand [new RandomVariable/Uniform]
$yrand use-rng $rng
$yrand set min_ [expr -$val(dimy)/2]
$yrand set max_ [expr $val(dimy)/2]

set trand [new RandomVariable/Uniform]
$trand use-rng $rng
$trand set min_ 0
$trand set max_ $val(interval)

#
# Create all the source nodes
#
for {set i 0} {$i < $val(nn)-1 } {incr i} {
    set src_node($i) [$ns node] 
    $src_node($i) random-motion 0
    set x [expr $val(dimx)/2 + [$xrand value]]
    set y [expr $val(dimx)/2 + [$xrand value]]
    $src_node($i) set X_ $x
    $src_node($i) set Y_ $y
    $src_node($i) set Z_ 0
    $ns initial_node_pos $src_node($i) $val(node_size)

    set udp($i) [new Agent/UDP]
    $udp($i) set class_ $i
    $ns attach-agent $src_node($i) $udp($i)
    $ns connect $udp($i) $sink

    set cbr($i) [new Application/Traffic/CBR]
    $cbr($i) set packetSize_ $val(packetsize)
    $cbr($i) set interval_ $val(interval)
    $cbr($i) attach-agent $udp($i)
    set start [$trand value]
    $ns at $start "$cbr($i) start"
 
    $ns at $val(duration) "$cbr($i) stop"
}


for {set i 0} {$i < $val(nn)-1 } {incr i} {
    $ns at $val(duration) "$src_node($i) reset";
}
$ns at $val(duration) "stop"
$ns at $val(duration) "puts \"NS EXITING...\" ; $ns halt"


proc stop {} {
    global ns tracefd stats val sink

    set bytes [$sink set bytes_]
    set losts  [$sink set nlost_]
    set pkts [$sink set npkts_]
    puts $stats "bytes losts pkts"
    puts $stats "$bytes $losts $pkts"

    $ns flush-trace
    close $tracefd
    close $stats
}

puts "Starting Simulation..."
$ns run
