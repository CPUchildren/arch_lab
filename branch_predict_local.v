module branch_predict_local (
    input wire clk, rst,
    

    input wire flushD,
    input wire stallD,
    
    input wire [31:0] pcF,
    input wire [31:0] pcM,
    
    input wire branchM,         // Mиж??????????????????????
    input wire actual_takeM,    // ???иж????????бж????
    
    input wire branchD,        // ??????иж????????????бж?????????   
    output wire pred_takeD      // иж???????????бж????

);
    wire pred_takeF;
    reg pred_takeF_r;


// ???????????бу
    parameter Strongly_not_taken = 2'b00, Weakly_not_taken = 2'b01, Weakly_taken = 2'b11, Strongly_taken = 2'b10;
    parameter PHT_DEPTH = 6;
    parameter BHT_DEPTH = 10;

// 
    reg [5:0] BHT [(1<<BHT_DEPTH)-1 : 0];
    reg [1:0] PHT [(1<<PHT_DEPTH)-1:0];
    

    integer i,j;
    wire [(PHT_DEPTH-1):0] PHT_index;
    wire [(BHT_DEPTH-1):0] BHT_index;
    wire [(PHT_DEPTH-1):0] BHR_value;

// ---------------------------------------иж?????иж?????---------------------------------------

    assign BHT_index = pcF[11:2];     
    assign BHR_value = BHT[BHT_index];  
    assign PHT_index = BHR_value;
    
    assign pred_takeF = PHT[PHT_index][1];      // ??бз??????иж?????иж??????????????бж????????????????????бу???????иж???????????иж???????
    
        // --------------------------pipeline------------------------------
            always @(posedge clk) begin
                if(rst | flushD) begin
                    pred_takeF_r <= 0;
                end
                else if(~stallD) begin
                    pred_takeF_r <= pred_takeF;
                end
            end
        // --------------------------pipeline------------------------------

// ---------------------------------------иж?????иж?????---------------------------------------


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
            // ??бш????????бж???????????????буиж??????????????
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
                PHT[i] <= Weakly_taken;
            end
        end
        else begin
            case(PHT[update_PHT_index])
                // ??бш????????бж???????????????буиж??????????????
                Strongly_not_taken:begin
                    if(actual_takeM) begin
                        PHT[update_PHT_index] <= Weakly_not_taken;
                    end
                    else begin
                        PHT[update_PHT_index] <= Strongly_not_taken;
                    end
                end
                Weakly_not_taken:begin
                    if(actual_takeM) begin
                        PHT[update_PHT_index] <= Strongly_taken;
                    end
                    else begin
                        PHT[update_PHT_index] <= Weakly_taken;
                    end
                end
                Strongly_taken:begin
                    if(actual_takeM) begin
                        PHT[update_PHT_index] <= Strongly_taken;
                    end
                    else begin
                        PHT[update_PHT_index] <= Weakly_taken;
                    end
                end
                Weakly_taken:begin
                    if(actual_takeM) begin
                        PHT[update_PHT_index] <= Strongly_taken;
                    end
                    else begin
                        PHT[update_PHT_index] <= Weakly_not_taken;
                    end
                end
            endcase 
        end
    end
// ---------------------------------------PHT????????????????????---------------------------------------

    // ??????иж???????????????????иж???????????
    assign pred_takeD = branchD & pred_takeF_r;  

endmodule