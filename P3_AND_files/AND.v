module AND_gate (
input B1,
input B0,
output  LED2,
output LED1,
output LED0   
);
// Button assignments 
assign BTN0 = !B0;
assign BTN1 = !B1;

// Add your code below
assign LED0 = BTN0; 
assign LED1 = BTN1; 
assign LED2 = BTN1 ^ BTN0;
 
endmodule