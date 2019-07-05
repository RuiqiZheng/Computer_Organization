`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/05/02 16:20:13
// Design Name: 
// Module Name: execute_unitx32
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module execute_unitx32(
    input[31:0]  Read_data_1,       // �����뵥Ԫ��Read_data_1����  R[rs]
    input[31:0]  Read_data_2,       // �����뵥Ԫ��Read_data_2����  R[rt]
    input[31:0]  Sign_extend,       // �����뵥Ԫ������չ���������
    input[5:0]   Function_opcode,   // ȡָ��Ԫ����r-����ָ�����,r-form instructions[5:0]
    input[5:0]   Exe_opcode,        // ȡָ��Ԫ���Ĳ�����
    input[1:0]   ALUOp,             // ���Կ��Ƶ�Ԫ������ָ����Ʊ���
    input[4:0]   Shamt,             // ����ȡָ��Ԫ��instruction[10:6]��ָ����λ����
    input wire   Sftmd,             // ���Կ��Ƶ�Ԫ�ģ���������λָ��
    input        ALUSrc,            // ���Կ��Ƶ�Ԫ�������ڶ�������������������beq��bne���⣩
    input        I_format,          // ���Կ��Ƶ�Ԫ�������ǳ�beq, bne, LW, SW֮���I-����ָ��
    input        Jrn,               // ���Կ��Ƶ�Ԫ��������JRָ��
    output       Zero,              // Ϊ1��������ֵΪ0 
    output reg[31:0] ALU_Result,    // ��������ݽ��
    output[31:0] Add_Result,        // ����ĵ�ַ���        
    input[31:0]  PC_plus_4          // ����ȡָ��Ԫ��PC+4
); 
    wire[31:0]  Ainput,Binput;
    reg[31:0]   Sinput;
    reg[31:0]   ALU_output_mux;
    wire[32:0]  Branch_Add;
    wire[2:0]   ALU_ctl;
    wire[5:0]   Exe_code;
    wire[2:0]   Sftm;
    
    assign Sftm = Function_opcode[2:0];   // ʵ�����õ�ֻ�е���λ(��λָ�
    assign Exe_code = (I_format==0) ? Function_opcode : {3'b000,Exe_opcode[2:0]};
    assign Ainput = Read_data_1;
    assign Binput = (ALUSrc == 0) ? Read_data_2 : Sign_extend[31:0]; //R/LW,SW  sft  else��ʱ��LW��SW
    assign ALU_ctl[0] = (Exe_code[0] | Exe_code[3]) & ALUOp[1];      //24H AND 
    assign ALU_ctl[1] = ((!Exe_code[2]) | (!ALUOp[1]));
    assign ALU_ctl[2] = (Exe_code[1] & ALUOp[1]) | ALUOp[0];

always @* begin  // 6����λָ��
       if(Sftmd)
        case(Sftm[2:0])
            3'b000:Sinput = Read_data_2 << Shamt;       //Sll rd,rt,shamt  00000
            3'b010:Sinput = Read_data_2 >> Shamt;       //Srl rd,rt,shamt  00010
            3'b100:Sinput = Read_data_2 << Read_data_1; //Sllu rd,rt,rs 000100
            3'b110:Sinput = Read_data_2 >> Read_data_1; //Srlu rd,rt,rs 000110
            3'b011:Sinput = ($signed(Read_data_2)) >>> Shamt;       //Sra rd,rt,shamt 00011
            3'b111:Sinput = ($signed(Read_data_2)) >>> Read_data_1; //Srav rd,rt,rs 00111
            default:Sinput = Binput;
        endcase
       else Sinput = Binput;
    end
 
    always @* begin
        if(((ALU_ctl==3'b111) && (Exe_code[3]==1))||((ALU_ctl[2:1]==2'b11) && (I_format==1))) //slti(sub)  ��������SLT�������
            ALU_Result = Read_data_1 < Read_data_2 ? 1'b1 : 1'b0;
        else if((ALU_ctl==3'b101) && (I_format==1)) // lui: load upper immediate
            ALU_Result[31:0] = {Binput[15:0], {16{1'b0}}};   
        else if(Sftmd==1)   // ��λ
            ALU_Result = Sinput;   
        else  ALU_Result = ALU_output_mux[31:0];    // otherwise
    end
 
    assign Branch_Add = PC_plus_4[31:2] + Sign_extend[31:0];
    assign Add_Result = Branch_Add[31:0];   //�������һ��PCֵ�Ѿ����˳�4���������Բ�������16λ
    assign Zero = (ALU_output_mux[31:0]== 32'h00000000) ? 1'b1 : 1'b0;
    
    always @(ALU_ctl or Ainput or Binput) begin
        case(ALU_ctl)
            3'b000:ALU_output_mux = Ainput & Binput;    // and, andi
            3'b001:ALU_output_mux = Ainput | Binput;    // or, ori
            3'b010:ALU_output_mux = Ainput + Binput;    // add, addi, lw, sw // �����ַ
            3'b011:ALU_output_mux = Ainput + Binput;    // addu, addiu
            3'b100:ALU_output_mux = Ainput ^ Binput;    // xor, xori
            3'b101:ALU_output_mux = ~(Ainput | Binput); // nor, lui
            3'b110:ALU_output_mux = Ainput - Binput;    // sub, slti, beq, bne
            3'b111:ALU_output_mux = Ainput - Binput;    // subu, sltiu, slt, sltu
            default:ALU_output_mux = 32'h00000000;
        endcase
    end
endmodule
