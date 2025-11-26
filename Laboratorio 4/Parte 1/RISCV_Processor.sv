module RISCV_Processor #(
  parameter int XLEN = 32
)(
        input  logic             clk_i, rst_i,   
        
        // ROM
        output logic  [XLEN-1:0] ProgAddress_o,
        input  logic  [XLEN-1:0] ProgIn_i,
                     
        // RAM       
        input  logic  [XLEN-1:0] DataIn_i,
        output logic  [XLEN-1:0] DataAddress_o,
        output logic  [XLEN-1:0] DataOut_o,
        output logic             we_o
);  
    

    // ---------------- Registros ---------------- 
    logic [XLEN-1:0] read_data, A, B, ALUOut;
    
    // Campos desde IR
    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [4:0] rd;

    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;
    
    assign rs1    = ProgIn_i[19:15];
    assign rs2    = ProgIn_i[24:20];
    assign rd     = ProgIn_i[11:7];
    assign opcode = ProgIn_i[6:0];
    assign funct3 = ProgIn_i[14:12];
    assign funct7 = ProgIn_i[31:25];
    
 //-------------------------------------------------------------------
 //                        Unidad de Control
 //-------------------------------------------------------------------
 
 logic        RegWrite    ;
 logic [1:0]  ImmSrc      ;
 logic        ALUSrc     ;
 logic        MemWrite    ;
 logic [1:0]  ResultSrc   ;
 logic        PCSrc       ;
 logic [3:0]  ALUControl  ;
 logic        Jump        ;
 logic Zero,less;
 
 control_unit CU (
    .opcode(opcode),
    .funct3(funct3),
    .funct7(funct7),
    .Zero(Zero),
    .less(less),
    .RegWrite(RegWrite),
    .ImmSrc(ImmSrc),
    .ALUSrc(ALUSrc),
    .MemWrite(MemWrite),
    .ResultSrc(ResultSrc),
    .PCSrc(PCSrc),
    .ALUControl(ALUControl),
    .Jump(Jump)
 );
 
 assign we_o = MemWrite;
 
 //-------------------------------------------------------------------
 //                            Inmediato
 //-------------------------------------------------------------------
    logic [XLEN-1:0] Imm;
    immgen_rv32 IMMGEN (
            .instr_d(ProgIn_i), 
            .ImmSel(ImmSrc), 
            .imm(Imm)
    );
    
//-------------------------------------------------------------------  
//                         Banco de Registros
//-------------------------------------------------------------------
    logic [XLEN-1:0] read_data1, read_data2,Result;
    
    register_file #(.DATA_WIDTH(XLEN)) RF 
        (
            .clk(clk_i), 
            .reset(rst_i), 
            .RegWrite(RegWrite),
            .rs1(rs1), 
            .rs2(rs2), 
            .rd(rd),
            .write_data(Result), 
            .read_data1(read_data1), 
            .read_data2(read_data2)
    );

// -------------------------------------------------------------------
//                                ALU
// -------------------------------------------------------------------
    logic [XLEN-1:0] srcA;
    logic [XLEN-1:0] srcB; 
    logic [XLEN-1:0] ALUResult;
    
    assign srcA = read_data1;
            
    ALU #(.XLEN(XLEN)) ALU (
            .A      (srcA),
            .B      (srcB),
            .ALUControl (ALUControl),
            .ALUOut (ALUResult),
            .Zero   (Zero),
            .less   (less)
    );
    
    assign DataAddress_o = ALUResult;

// -------------------------------------------------------------------
//                          Multiplexores
// -------------------------------------------------------------------  
      logic [XLEN-1:0] PC, PCNext;
      logic [XLEN-1:0] PC4,PCTarget;
      
      assign PC4 = PC + XLEN'(4);
      assign PCTarget = PC + Imm;
      
      // Mux de PC //
      mux2_1 #(.N(XLEN)) muxPCNext (
        .d0(PC4),
        .d1(PCTarget),
        .sel(PCSrc),
        .y(PCNext)
      );
      
      // Registro Sincronico PC //
      always_ff @(posedge clk_i or posedge rst_i) begin
          if (rst_i) 
              PC <= '0;           // Reinicia PC a 0
          else 
              PC <= PCNext;      // Actualiza PC con el valor siguiente
      end
      
      assign ProgAddress_o = PC;

      // MUX de srcB //
      mux2_1 #(.N(XLEN)) muxSrcB(
        .d0(read_data2),
        .d1(Imm),
        .sel(ALUSrc),
        .y(srcB)
      );
      
      // Mux de Resultado //
      logic [XLEN-1:0] ReadData; 
      assign ReadData = DataIn_i;
      
      mux3_1 #(.N(XLEN)) muxResult(
        .d0(ALUResult),
        .d1(ReadData),
        .d2(PC4),
        .sel(ResultSrc),
        .y(Result)
      );
      
      assign DataOut_o = read_data2;

endmodule
