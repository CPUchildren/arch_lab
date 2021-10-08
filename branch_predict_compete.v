module branch_predict_compete (
    input wire clk, rst,
    
    input wire [31:0] pcF,
    input wire [31:0] pcM,
    input wire flushD,
    input wire stallD,

    input wire errorM,         // 在M阶段返回是否判断错误

    input wire branchM,         // M是否是分支指令
    input wire actual_takeM,    // 是否真的在M阶段跳转
    
    input wire branchF,
    input wire branchD,        //   D阶段是否是分支指令  
    output wire  pred_takeD      //  是否需要跳转
);
    wire Gpred_takeF;
    reg Gpred_takeF_r;

    wire Gpred_takeD;
    wire Bpred_takeD;
    wire clear,ena;
    assign clear = 1'b0;
    assign ena = 1'b1;


// ???????????°
    parameter Strongly_not_taken = 2'b00, Weakly_not_taken = 2'b01, Weakly_taken = 2'b11, Strongly_taken = 2'b10;
    parameter PHT_DEPTH = 6;
    parameter BHT_DEPTH = 10;

    reg [1:0] GPHT [(1<<PHT_DEPTH)-1 : 0];

    reg [(PHT_DEPTH-1):0] GHR;          // Global History Register
    reg [(PHT_DEPTH-1):0] RGHR;         // Repaired GHR
// ---------------------------------------GHR在预测阶段根据预测值更新------------------------------------
    always@(posedge clk) begin
        if(rst) begin
            GHR <= 0;
        end
        else if(branchF) begin
            GHR <= (GHR<<1) + (Gpred_takeF & branchF);   // 根据预测值更新
        end
        else if(errorM) begin
            GHR[0] <= RGHR[0];
        end
    end
// ---------------------------------------GHR在预测阶段根据预测值更新------------------------------------



// ----------------------------------Repair GHT根据M阶段是否真实跳转更新---------------------------------

    always@(posedge clk) begin
        if(rst) begin
            RGHR <= 0;
        end
        else if(branchM) begin
            RGHR <= (RGHR<<1) + actual_takeM;
        end
    end
// ----------------------------------Repair GHT根据M阶段是否真实跳转更新---------------------------------


    integer i,j;

// ---------------------------------------预测本条指令是否跳转-------------------------------------------
    assign Gpred_takeF = GPHT[GHR][1];      // 预测是否跳转

// --------------------------pipeline-----------------------------
    always @(posedge clk) begin     //延迟一周期
        if(rst | flushD) begin
            Gpred_takeF_r <= 0;
        end
        else if(~stallD) begin
            Gpred_takeF_r <= Gpred_takeF;
        end
    end
// --------------------------pipeline-----------------------------

// ---------------------------------------预测本条指令是否跳转-------------------------------------------


// ----------------------------------Repair GHT根据M阶段是否真实跳转更新---------------------------------

    always@(posedge clk) begin
        if(rst) begin
            RGHR <= 0;
        end
        else if(actual_takeM) begin
            RGHR <= (RGHR<<1) + actual_takeM;
        end
    end
// ----------------------------------Repair GHT根据M阶段是否真实跳转更新--------------------------------


// ---------------------------------------PHT鍒濆?鍖栦互鍙婃洿鏂?---------------------------------------
    always @(posedge clk) begin
        if(rst) begin
            for(i = 0; i < (1<<PHT_DEPTH); i=i+1) begin
                GPHT[i] <= Weakly_taken;
            end
        end
        else begin
            case(GPHT[RGHR])
                // 姝ゅ?搴旇?娣诲姞浣犵殑鏇存柊閫昏緫鐨勪唬鐮?
                Strongly_not_taken:begin
                    if(actual_takeM) begin
                        GPHT[RGHR] <= Weakly_not_taken;
                    end
                    else begin
                        GPHT[RGHR] <= Strongly_not_taken;
                    end
                end
                Weakly_not_taken:begin
                    if(actual_takeM) begin
                        GPHT[RGHR] <= Strongly_taken;
                    end
                    else begin
                        GPHT[RGHR] <= Weakly_taken;
                    end
                end
                Strongly_taken:begin
                    if(actual_takeM) begin
                        GPHT[RGHR] <= Strongly_taken;
                    end
                    else begin
                        GPHT[RGHR] <= Weakly_taken;
                    end
                end
                Weakly_taken:begin
                    if(actual_takeM) begin
                        GPHT[RGHR] <= Strongly_taken;
                    end
                    else begin
                        GPHT[RGHR] <= Weakly_not_taken;
                    end
                end
            endcase 
        end
    end
// ---------------------------------------PHT鍒濆?鍖栦互鍙婃洿鏂?---------------------------------------

    // 璇戠爜闃舵?杈撳嚭鏈?缁堢殑棰勬祴缁撴灉
    assign Gpred_takeD = branchD & Gpred_takeF_r;  

////////////////////////////////////////////////////分界线////// 上global   下local


    wire Bpred_takeF;
    reg Bpred_takeF_r;

// 
    reg [5:0] BHT [(1<<BHT_DEPTH)-1 : 0];
    reg [1:0] BPHT [(1<<PHT_DEPTH)-1:0];
    
    wire [(PHT_DEPTH-1):0] PHT_index;
    wire [(BHT_DEPTH-1):0] BHT_index;
    wire [(PHT_DEPTH-1):0] BHR_value;

// ---------------------------------------é?????é?????---------------------------------------

    assign BHT_index = pcF[11:2];     
    assign BHR_value = BHT[BHT_index];  
    assign PHT_index = BHR_value;
    
    assign Bpred_takeF = BPHT[PHT_index][1];      // ??¨??????é?????é??????????????ˇ????????????????????°???????é???????????é???????
    
        // --------------------------pipeline------------------------------
            always @(posedge clk) begin
                if(rst | flushD) begin
                    Bpred_takeF_r <= 0;
                end
                else if(~stallD) begin
                    Bpred_takeF_r <= Bpred_takeF;
                end
            end
        // --------------------------pipeline------------------------------

// ---------------------------------------é?????é?????---------------------------------------


// ---------------------------------------BHT????????????????????---------------------------------------
    wire [(PHT_DEPTH-1):0] update_PHT_index;
    wire [(BHT_DEPTH-1):0] update_BHT_index;
    wire [(PHT_DEPTH-1):0] update_BHR_value;

    assign update_BHT_index = pcM[11:2];     
    assign update_BHR_value = BHT[update_BHT_index];  
    assign update_PHT_index = update_BHR_value;
    
    always@(posedge clk) begin
        if(rst) begin
            for(j = 0; j < (1<<BHT_DEPTH); j=j+1) begin
                BHT[j] <= 0;
            end
        end
        else if(branchM) begin
            // ??¤????????ˇ???????????????°é??????????????
            if(actual_takeM) begin
                BHT[update_BHT_index] <= (update_BHR_value<<1)+1;
            end
            else begin
                BHT[update_BHT_index] <= (update_BHR_value<<1);
            end
        end
    end

// ---------------------------------------BHT????????????????????---------------------------------------


// ---------------------------------------PHT????????????????????---------------------------------------
    always @(posedge clk) begin
        if(rst) begin
            for(i = 0; i < (1<<PHT_DEPTH); i=i+1) begin
                BPHT[i] <= Weakly_taken;
            end
        end
        else begin
            case(BPHT[update_PHT_index])
                // ??¤????????ˇ???????????????°é??????????????
                Strongly_not_taken:begin
                    if(actual_takeM) begin
                        BPHT[update_PHT_index] <= Weakly_not_taken;
                    end
                    else begin
                        BPHT[update_PHT_index] <= Strongly_not_taken;
                    end
                end
                Weakly_not_taken:begin
                    if(actual_takeM) begin
                        BPHT[update_PHT_index] <= Strongly_taken;
                    end
                    else begin
                        BPHT[update_PHT_index] <= Weakly_taken;
                    end
                end
                Strongly_taken:begin
                    if(actual_takeM) begin
                        BPHT[update_PHT_index] <= Strongly_taken;
                    end
                    else begin
                        BPHT[update_PHT_index] <= Weakly_taken;
                    end
                end
                Weakly_taken:begin
                    if(actual_takeM) begin
                        BPHT[update_PHT_index] <= Strongly_taken;
                    end
                    else begin
                        BPHT[update_PHT_index] <= Weakly_not_taken;
                    end
                end
            endcase 
        end
    end
// ---------------------------------------PHT????????????????????---------------------------------------

    // ??????é???????????????????é???????????
    assign Bpred_takeD = branchD & Bpred_takeF_r;


    wire Gpred_takeE,Gpred_takeM;
    wire Bpred_takeE,Bpred_takeM;


    flopenrc #(1) GpreE(clk,rst,clear,ena,Gpred_takeD,Gpred_takeE);
    flopenrc #(1) GpreM(clk,rst,clear,ena,Gpred_takeE,Gpred_takeM);

    flopenrc #(1) BpreE(clk,rst,clear,ena,Bpred_takeD,Bpred_takeE);
    flopenrc #(1) BpreM(clk,rst,clear,ena,Bpred_takeE,Bpred_takeM);

    wire Gcorr,Bcorr;
    assign Gcorr = Gpred_takeM & actual_takeM;
    assign Bcorr = Bpred_takeM & actual_takeM;

    wire sigs;
    assign sigs={Gcorr,Bcorr};
    

//////// CPHT
    reg [2:0] CPHT [ (1<<BHT_DEPTH)-1 : 0];
    wire CPHT_index;
    assign CPHT_index = pcM[11:2];   

    parameter Strongly_global = 2'b00, Weakly_global = 2'b01, Weakly_local = 2'b10, Strongly_local = 2'b11;

    always @(posedge clk) begin
        if(rst) begin
            for(i = 0; i < (1<<BHT_DEPTH); i=i+1) begin
                CPHT[i] <= Strongly_global;
            end
        end
        else begin
            case(CPHT[CPHT_index])
                // ??¤????????ˇ???????????????°é??????????????
                Strongly_global:begin
                    if(sigs==2'b00 || sigs==2'b11 || sigs==2'b10) begin
                        CPHT[CPHT_index] <= Strongly_global;
                    end
                    else begin
                        CPHT[CPHT_index] <= Weakly_global;
                    end
                end
                Weakly_global:begin
                    if(sigs==2'b10) begin
                        CPHT[CPHT_index] <= Strongly_global;
                    end
                    else if(sigs==2'b01) begin
                        CPHT[CPHT_index] <= Weakly_local;
                    end
                    else begin
                        CPHT[CPHT_index] <= Weakly_global;
                    end
                end
                Weakly_local:begin
                    if(sigs==2'b10) begin
                        CPHT[CPHT_index] <= Weakly_global;
                    end
                    else if(sigs==2'b01) begin
                        CPHT[CPHT_index] <= Strongly_local;
                    end
                    else begin
                        CPHT[CPHT_index] <= Weakly_local;
                    end
                end
                Strongly_local:begin
                    if(sigs==2'b00 || sigs==2'b11 || sigs==2'b01) begin
                        CPHT[CPHT_index] <= Strongly_local;
                    end
                    else begin
                        CPHT[CPHT_index] <= Weakly_local;
                    end
                end



            endcase 
        end
    end

    wire pred_chooseF,pred_chooseD;
    assign pred_chooseF=CPHT[pcF[11:2]][1];
    flopenrc #(1) prechoose(clk,rst,clear,ena,pred_chooseF,pred_chooseD);
    
    assign pred_takeD= (pred_chooseD==1'b0)?Gpred_takeD:Bpred_takeD;

endmodule