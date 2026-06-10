module adder (
    input logic clk,
    input logic rst_n,
    input logic [7:0] a,
    input logic [7:0] b,
    output logic [8:0] y
);

    always_ff @( posedge clk or negedge rst_n ) begin
        if(!rst_n) begin
            y <= 0;
        end else begin
            y <= a + b;
        end
    end
    
endmodule