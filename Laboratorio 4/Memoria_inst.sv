module instr_mem #(
  parameter int DEPTH = 1024
)(
  input  logic        clk,
  input  logic        reset,
  input  logic        MemRead,       // enable de lectura
  input  logic [63:0] mem_addr,      // PC
  output logic [31:0] instr,        // instrucción
  output logic        instr_valid
);
  localparam int AW = $clog2(DEPTH);
  logic [31:0] mem [0:DEPTH-1];
  logic [AW-1:0] idx;

  // inicializa programa
  initial begin
    integer i;
    for (i=0; i<DEPTH; i++) mem[i] = 32'h00000013; 
        mem[0]  = 32'h00500093; // addi x1, x0, 5
        mem[1]  = 32'h00500113; // addi x2, x0, 5
        mem[2]  = 32'h002081b3; // add  x3, x1, x2
        mem[3]  = 32'h40208233; // sub  x4, x1, x2
        mem[4]  = 32'h0020e2b3; // or   x5, x1, x2
        mem[5]  = 32'h0020f333; // and  x6, x1, x2
        mem[6]  = 32'h00001397; // auipc x7, 0x1      
        mem[7]  = 32'h0080046f; // jal  x8, +8        
        mem[8]  = 32'h06300493; // addi x9, x0, 99    
        mem[9]  = 32'h00208463; // beq  x1, x2, +8    
        mem[10] = 32'h00209463; // bne  x1, x2, +8    
        mem[11] = 32'h03700513; // addi x10,x0,55     
        mem[12] = 32'h00303023; // sd   x3, 0(x0)     
        mem[13] = 32'h00700113; // addi x2, x0, 7     
        mem[14] = 32'h00209463; // bne  x1, x2, +8
        mem[15] = 32'h05500593; // addi x11, x0, 85  
        mem[16] = 32'h00003583; // ld   x11, 0(x0)   
  end

  assign idx = mem_addr[AW+1:2]; // PC / 4

    always_comb begin
      if (MemRead) begin
        instr <= mem[idx];
        instr_valid     <= 1'b1;
      end else begin
        instr_valid <= 1'b0;
      end
    end
endmodule

