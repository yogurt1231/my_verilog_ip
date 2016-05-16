#wb_avalon  
A verilog project that order to bridge wishbone bus with avalon bus.  
  
###WishBone Slave to Avalon Master IP  
WishBone Slave to Avalon Master IP can convert wishbone slave bus to avalon master bus.  
So you can use a wishbone cpu to access a avalon ip core.  
  
Example:  
(or1200) wb_master----->wb_slave (wb_avalon ip) avalon_master----->avalon_slave (sdram)  
  
###Avalon Slave to WishBone Master IP  
Avalon Slave to WishBone Master IP can convert avalon slave bus to master master bus.  
So you can use a avalon cpu to access a wishbone ip core.  
  
Example:  
(nios2) avalon_master----->avalon_slave (avalon_wb ip) wb_master----->wb_slave (uart16550)
