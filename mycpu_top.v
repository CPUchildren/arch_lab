// 结构
//           ---------------------------------------    mycpu_top.v
//        |   -------------------------    mips core|
//        |   |        data_path       |            |
//        |   -------------------------             |
//        |        | sram       | sram              |
//        |      ----           ----                |
//        |     |    |         |    |               |
//        |      ----           ----                |
//        |        | sram-like    | sram-like       |
//           ---------------------------------------
//                 | sram-like    | sram-like
//           ---------------------------------------
//        |    								cache    |
//        |    								         |
//           ---------------------------------------
//                 | sram-like    | sram-like
//           ---------------------------------------
//        |    			cpu_axi_interface(longsoon)  |
//        |    								         |
//           ---------------------------------------
//          			        | axi

module mycpu_top(
    input [5:0] ext_int,   //high active  //input

    input wire aclk,    
    input wire aresetn,   //low active

    output wire[3:0] arid,
    output wire[31:0] araddr,
    output wire[7:0] arlen,
    output wire[2:0] arsize,
    output wire[1:0] arburst,
    output wire[1:0] arlock,
    output wire[3:0] arcache,
    output wire[2:0] arprot,
    output wire arvalid,
    input wire arready,
                
    input wire[3:0] rid,
    input wire[31:0] rdata,
    input wire[1:0] rresp,
    input wire rlast,
    input wire rvalid,
    output wire rready, 
               
    output wire[3:0] awid,
    output wire[31:0] awaddr,
    output wire[7:0] awlen,
    output wire[2:0] awsize,
    output wire[1:0] awburst,
    output wire[1:0] awlock,
    output wire[3:0] awcache,
    output wire[2:0] awprot,
    output wire awvalid,
    input wire awready,
    
    output wire[3:0] wid,
    output wire[31:0] wdata,
    output wire[3:0] wstrb,
    output wire wlast,
    output wire wvalid,
    input wire wready,
    
    input wire[3:0] bid,
    input wire[1:0] bresp,
    input bvalid,
    output bready,

    //debug interface
    output wire[31:0] debug_wb_pc,
    output wire[3:0] debug_wb_rf_wen,
    output wire[4:0] debug_wb_rf_wnum,
    output wire[31:0] debug_wb_rf_wdata
);
wire clk, rst;
assign clk = aclk;
assign rst = ~aresetn;

wire        cpu_inst_req  ;
wire [31:0] cpu_inst_addr ;
wire        cpu_inst_wr   ;
wire [1:0]  cpu_inst_size ;
wire [31:0] cpu_inst_wdata;
wire [31:0] cpu_inst_rdata;
wire        cpu_inst_addr_ok;
wire        cpu_inst_data_ok;

wire        cpu_data_req  ;
wire [31:0] cpu_data_addr ;
wire        cpu_data_wr   ;
wire [1:0]  cpu_data_size ;
wire [31:0] cpu_data_wdata;
wire [31:0] cpu_data_rdata;
wire        cpu_data_addr_ok;
wire        cpu_data_data_ok;

wire [31:0] i_araddr  ;
wire [7 :0] i_arlen   ;
wire [2 :0] i_arsize  ;
wire        i_arvalid ;
wire        i_arready ;
wire [31:0] i_rdata   ;
wire        i_rlast   ;
wire        i_rvalid  ;
wire        i_rready  ;

wire [31:0] d_araddr  ;
wire [7 :0] d_arlen   ;
wire [2 :0] d_arsize  ;
wire        d_arvalid ;
wire        d_arready ;
wire [31:0] d_rdata   ;
wire        d_rlast   ;
wire        d_rvalid  ;
wire        d_rready  ;
wire [31:0] d_awaddr  ;
wire [7 :0] d_awlen   ;
wire [2 :0] d_awsize  ;
wire        d_awvalid ;
wire        d_awready ;
wire [31:0] d_wdata   ;
wire [3 :0] d_wstrb   ;
wire        d_wlast   ;
wire        d_wvalid  ;
wire        d_wready  ;
wire        d_bvalid  ;
wire        d_bready  ;

wire        ram_data_req  ;
wire [31:0] ram_data_addr ;
wire        ram_data_wr   ;
wire [1:0]  ram_data_size ;
wire [31:0] ram_data_wdata;
wire [31:0] ram_data_rdata;
wire        ram_data_addr_ok;
wire        ram_data_data_ok;

wire        conf_data_req  ;
wire [31:0] conf_data_addr ;
wire        conf_data_wr   ;
wire [1:0]  conf_data_size ;
wire [31:0] conf_data_wdata;
wire [31:0] conf_data_rdata;
wire        conf_data_addr_ok;
wire        conf_data_data_ok;

wire        wrap_data_req  ;
wire [31:0] wrap_data_addr ;
wire        wrap_data_wr   ;
wire [1:0]  wrap_data_size ;
wire [31:0] wrap_data_wdata;
wire [31:0] wrap_data_rdata;
wire        wrap_data_addr_ok;
wire        wrap_data_data_ok;

mips_core mips_core(
    .clk(clk), .rst(rst),
    .ext_int(ext_int),

    .inst_req     (cpu_inst_req  ),
    .inst_wr      (cpu_inst_wr   ),
    .inst_addr    (cpu_inst_addr ),
    .inst_size    (cpu_inst_size ),
    .inst_wdata   (cpu_inst_wdata),
    .inst_rdata   (cpu_inst_rdata),
    .inst_addr_ok (cpu_inst_addr_ok),
    .inst_data_ok (cpu_inst_data_ok),

    .data_req     (cpu_data_req  ),
    .data_wr      (cpu_data_wr   ),
    .data_addr    (cpu_data_addr ),
    .data_wdata   (cpu_data_wdata),
    .data_size    (cpu_data_size ),
    .data_rdata   (cpu_data_rdata),
    .data_addr_ok (cpu_data_addr_ok),
    .data_data_ok (cpu_data_data_ok),

    .debug_wb_pc       (debug_wb_pc       ),
    .debug_wb_rf_wen   (debug_wb_rf_wen   ),
    .debug_wb_rf_wnum  (debug_wb_rf_wnum  ),
    .debug_wb_rf_wdata (debug_wb_rf_wdata )
);

wire [31:0] cpu_inst_paddr;
wire [31:0] cpu_data_paddr;
wire no_dcache;

//将虚拟地址转换成物理地址，并判断是否需要经过Data Cache
mmu mmu(
    .inst_vaddr(cpu_inst_addr ),
    .inst_paddr(cpu_inst_paddr),
    .data_vaddr(cpu_data_addr ),
    .data_paddr(cpu_data_paddr),
    .no_dcache (no_dcache    )
);

//根据是否经过Cache，将信号分为两路
bridge_1x2 bridge_1x2(
    .no_dcache        (no_dcache    ),

    .cpu_data_req     (cpu_data_req  ),
    .cpu_data_wr      (cpu_data_wr   ),
    .cpu_data_addr    (cpu_data_paddr ),    //paddr
    .cpu_data_wdata   (cpu_data_wdata),
    .cpu_data_size    (cpu_data_size ),
    .cpu_data_rdata   (cpu_data_rdata),
    .cpu_data_addr_ok (cpu_data_addr_ok),
    .cpu_data_data_ok (cpu_data_data_ok),

    .ram_data_req     (ram_data_req  ),
    .ram_data_wr      (ram_data_wr   ),
    .ram_data_addr    (ram_data_addr ),
    .ram_data_wdata   (ram_data_wdata),
    .ram_data_size    (ram_data_size ),
    .ram_data_rdata   (ram_data_rdata),
    .ram_data_addr_ok (ram_data_addr_ok),
    .ram_data_data_ok (ram_data_data_ok),

    .conf_data_req     (conf_data_req  ),
    .conf_data_wr      (conf_data_wr   ),
    .conf_data_addr    (conf_data_addr ),
    .conf_data_wdata   (conf_data_wdata),
    .conf_data_size    (conf_data_size ),
    .conf_data_rdata   (conf_data_rdata),
    .conf_data_addr_ok (conf_data_addr_ok),
    .conf_data_data_ok (conf_data_data_ok)
);

//cache
cache cache (
    .clk(clk), .rst(rst),
    //mips core
    .cpu_inst_req     (cpu_inst_req     ),
    .cpu_inst_wr      (cpu_inst_wr      ),
    .cpu_inst_size    (cpu_inst_size    ),
    .cpu_inst_addr    (cpu_inst_addr    ),
    .cpu_inst_wdata   (cpu_inst_wdata   ),
    .cpu_inst_rdata   (cpu_inst_rdata   ),
    .cpu_inst_addr_ok (cpu_inst_addr_ok ),
    .cpu_inst_data_ok (cpu_inst_data_ok ),

    .cpu_data_req     (cpu_data_req     ),
    .cpu_data_wr      (cpu_data_wr      ),
    .cpu_data_size    (cpu_data_size    ),
    .cpu_data_addr    (cpu_data_addr    ),
    .cpu_data_wdata   (cpu_data_wdata   ),
    .cpu_data_rdata   (cpu_data_rdata   ),
    .cpu_data_addr_ok (cpu_data_addr_ok ),
    .cpu_data_data_ok (cpu_data_data_ok ),

    //axi interface
    // icache
    // ar
    .i_araddr  (i_araddr  ),
    .i_arlen   (i_arlen   ),
    .i_arsize  (i_arsize  ),
    .i_arvalid (i_arvalid ),
    .i_arready (i_arready ),
    // r
    .i_rdata   (i_rdata   ),
    .i_rlast   (i_rlast   ),
    .i_rvalid  (i_rvalid  ),
    .i_rready  (i_rready  ),

    // dcache
    // ar
    .d_araddr  (d_araddr  ),
    .d_arlen   (d_arlen   ),
    .d_arsize  (d_arsize  ),
    .d_arvalid (d_arvalid ),
    .d_arready (d_arready ),
    // r
    .d_rdata   (d_rdata   ),
    .d_rlast   (d_rlast   ),
    .d_rvalid  (d_rvalid  ),
    .d_rready  (d_rready  ),
    // aw
    .d_awaddr  (d_awaddr  ),
    .d_awlen   (d_awlen   ),
    .d_awsize  (d_awsize  ),
    .d_awvalid (d_awvalid ),
    .d_awready (d_awready ),
    // w
    .d_wdata   (d_wdata   ),
    .d_wstrb   (d_wstrb   ),
    .d_wlast   (d_wlast   ),
    .d_wvalid  (d_wvalid  ),
    .d_wready  (d_wready  ),
    // b
    .d_bvalid  (d_bvalid  ),
    .d_bready  (d_bready  )
);

//根据是否经过Cache，将信号合为一路
bridge_2x1 bridge_2x1(
    .no_dcache        (no_dcache    ),

    .ram_data_req     (cache_data_req  ),
    .ram_data_wr      (cache_data_wr   ),
    .ram_data_addr    (cache_data_addr ),
    .ram_data_wdata   (cache_data_wdata),
    .ram_data_size    (cache_data_size ),
    .ram_data_rdata   (cache_data_rdata),
    .ram_data_addr_ok (cache_data_addr_ok),
    .ram_data_data_ok (cache_data_data_ok),

    .conf_data_req     (conf_data_req  ),
    .conf_data_wr      (conf_data_wr   ),
    .conf_data_addr    (conf_data_addr ),
    .conf_data_wdata   (conf_data_wdata),
    .conf_data_size    (conf_data_size ),
    .conf_data_rdata   (conf_data_rdata),
    .conf_data_addr_ok (conf_data_addr_ok),
    .conf_data_data_ok (conf_data_data_ok),

    .wrap_data_req     (wrap_data_req  ),
    .wrap_data_wr      (wrap_data_wr   ),
    .wrap_data_addr    (wrap_data_addr ),
    .wrap_data_wdata   (wrap_data_wdata),
    .wrap_data_size    (wrap_data_size ),
    .wrap_data_rdata   (wrap_data_rdata),
    .wrap_data_addr_ok (wrap_data_addr_ok),
    .wrap_data_data_ok (wrap_data_data_ok)
);

axi_arbitrater axi_arbitrater(
    .clk(clk), .rst(rst),
    //I CACHE 从方
    .i_araddr(i_araddr)     ,
    .i_arlen(i_arlen)       ,
    .i_arvalid(i_arvalid)   ,
    .i_arready(i_arready)   ,

    .i_rdata(i_rdata)       ,
    .i_rlast(i_rlast)       ,
    .i_rvalid(i_rvalid)     ,
    .i_rready(i_rready)     ,

    //D CACHE 从方
    .d_araddr(d_araddr)     ,
    .d_arlen(d_arlen)       ,
    .d_arsize(d_arsize)     ,
    .d_arvalid(d_arvalid)   ,
    .d_arready(d_arready)   ,

    .d_rdata(d_rdata)       ,
    .d_rlast(d_rlast)       ,
    .d_rvalid(d_rvalid)     ,
    .d_rready(d_rready)     ,
    //write
    .d_awaddr(d_awaddr)     ,
    .d_awlen(d_awlen)       ,
    .d_awsize(d_awsize)     ,
    .d_awvalid(d_awvalid)   ,
    .d_awready(d_awready)   ,
    
    .d_wdata(d_wdata)       ,
    .d_wstrb(d_wstrb)       ,
    .d_wlast(d_wlast)       ,
    .d_wvalid(d_wvalid)     ,
    .d_wready(d_wready)     ,

    .d_bvalid(d_bvalid)     ,
    .d_bready(d_bready)     ,
    
    //Outer 主方
    .arid(arid)             ,
    .araddr(araddr)         ,
    .arlen(arlen)           ,
    .arsize(arsize)         ,
    .arburst(arburst)       ,
    .arlock(arlock)         ,
    .arcache(arcache)       ,
    .arprot(arprot)         ,
    .arvalid(arvalid)       ,
    .arready(arready)       ,
                
    .rid(rid)               ,
    .rdata(rdata)           ,
    .rresp(rresp)           ,
    .rlast(rlast)           ,
    .rvalid(rvalid)         ,
    .rready(rready)         ,
               
    .awid(awid)             ,
    .awaddr(awaddr)         ,
    .awlen(awlen)           ,
    .awsize(awsize)         ,
    .awburst(awburst)       ,
    .awlock(awlock)         ,
    .awcache(awcache)       ,
    .awprot(awprot)         ,
    .awvalid(awvalid)       ,
    .awready(awready)       ,
    
    .wid(wid)               ,
    .wdata(wdata)           ,
    .wstrb(wstrb)           ,
    .wlast(wlast)           ,
    .wvalid(wvalid)         ,
    .wready(wready)         ,
    
    .bid(bid)               ,
    .bresp(bresp)           ,
    .bvalid(bvalid)         ,
    .bready(bready)
);

endmodule