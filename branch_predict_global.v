module branch_predict_global (
    input wire clk, rst,
    
    input wire flushD,
    input wire stallD,

    input wire errorM,         // 在M阶段返回是否判断错误

    input wire branchM,         // M是否是分支指令
    input wire actual_takeM,    // 是否真的在M阶段跳转
    
    input wire branchF,
    input wire branchD,        //   D阶段是否是分支指令  
    output wire pred_takeD      //  是否需要跳转
);
    wire pred_takeF;
    reg pred_takeF_r;

// 瀹氫箟鍙傛暟
    parameter Strongly_not_taken = 2'b00, Weakly_not_taken = 2'b01, Weakly_taken = 2'b11, Strongly_taken = 2'b10;
    parameter PHT_DEPTH = 6;
    parameter BHT_DEPTH = 10;

// 
    reg [5:0] BHT [(1<<BHT_DEPTH)-1 : 0];
    reg [1:0] PHT [(1<<PHT_DEPTH)-1 : 0];


    reg [(PHT_DEPTH-1):0] GHR;          // Global History Register
    reg [(PHT_DEPTH-1):0] RGHR;         // Repaired GHR
// ---------------------------------------GHR在预测阶段根据预测值更新------------------------------------
    always@(posedge clk) begin
        if(rst) begin
            GHR <= 0;
        end
        else if(branchF) begin
            GHR <= (GHR<<1) + (pred_takeF & branchF);   // 根据预测值更新
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
    assign pred_takeF = PHT[GHR][1];      // 预测是否跳转

// --------------------------pipeline-----------------------------
    always @(posedge clk) begin     //延迟一周期
        if(rst | flushD) begin
            pred_takeF_r <= 0;
        end
        else if(~stallD) begin
            pred_takeF_r <= pred_takeF;
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
                PHT[i] <= Weakly_taken;
            end
        end
        else begin
            case(PHT[RGHR])
                // 姝ゅ?搴旇?娣诲姞浣犵殑鏇存柊閫昏緫鐨勪唬鐮?
                Strongly_not_taken:begin
                    if(actual_takeM) begin
                        PHT[RGHR] <= Weakly_not_taken;
                    end
                    else begin
                        PHT[RGHR] <= Strongly_not_taken;
                    end
                end
                Weakly_not_taken:begin
                    if(actual_takeM) begin
                        PHT[RGHR] <= Strongly_taken;
                    end
                    else begin
                        PHT[RGHR] <= Weakly_taken;
                    end
                end
                Strongly_taken:begin
                    if(actual_takeM) begin
                        PHT[RGHR] <= Strongly_taken;
                    end
                    else begin
                        PHT[RGHR] <= Weakly_taken;
                    end
                end
                Weakly_taken:begin
                    if(actual_takeM) begin
                        PHT[RGHR] <= Strongly_taken;
                    end
                    else begin
                        PHT[RGHR] <= Weakly_not_taken;
                    end
                end
            endcase 
        end
    end
// ---------------------------------------PHT鍒濆?鍖栦互鍙婃洿鏂?---------------------------------------

    // 璇戠爜闃舵?杈撳嚭鏈?缁堢殑棰勬祴缁撴灉
    assign pred_takeD = branchD & pred_takeF_r;  
endmodule