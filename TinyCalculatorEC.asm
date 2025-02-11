;TITLE TinyCalcultorEC.asm 
; Tiny Calculator with Assignment Operation
; Author: Shivam Pathak
; Date: 12/7/24
;Desc: This is a calcutlator progran that takes a users input and does a given math operation
;based on the users choice and provides a summary after with the addition of an operator
;that assings values to charecters 
;Status: Does not display charecter properley but the other logic with adding M and X together remain the same 


INCLUDE Irvine32.inc

.data
; Messages
.data
; Messages
welcomeMsg byte "Welcome to The Calculator", 0
menuMsg byte "Choose an operation:", 0
menuOps byte "Addition(a/A),Subtraction(s/S),Multiplication(m/M),Divison(d,D),Recall Memory(R,r),Assingment(=)", 0
inputPrompt byte "Enter your choice: ", 0
invalidChoice byte "Invalid choice,please try again.", 0
resultMsg byte "Result: ", 0
exitPrompt byte "Perform another operation? (Y/N): ", 0
finalReport byte "Final Report:", 0
opCountMsg byte "Total operations performed: ", 0
sumMsg byte "Running total: ", 0
avgMsg byte "Average of results: ", 0
enterFirstNum byte "Enter the first number: ", 0
enterSecondNum byte "Enter the second number: ", 0
errorMsg byte "Error: Division by zero is not allowed.", 0
memoryMsg byte "Current value in memory: ", 0
overflowMsg byte "Error: Overflow occurred during the operation.", 0
memoryResult dword 0 ; To store the result of operations in memory
divS byte " / ", 0 ; Division operator symbol
equalS byte " = ", 0 ; Equals symbol



; Counters and Variables
opCount dword 0
addCount dword 0
subCount dword 0
mulCount dword 0
divCount dword 0
modCount dword 0

savedMem dword 0
runningTotal dword 0
tempResult dword 0
leftOperand dword 0
rightOperand dword 0
userChoice byte 0
variables dword 26 dup(0) ; Array for variables A-Z, initialized to 0

.code
;-----------------------------------------------------------------
; Procedure: main
; Description: Entry point of the program. Displays a welcome message
;              and enters the main loop for user interaction.
; Receives: Nothing
; Returns: Nothing
;-----------------------------------------------------------------
main PROC
    call cls                       ; Clear screen
    lea eax, welcomeMsg
    call print                     ; Display welcome message
    call main_loop                 ; Start the main loop
    ret
main ENDP
;-----------------------------------------------------------------
; Procedure: main_loop
; Description: Manages the program's primary workflow, including
;              displaying the menu, handling user input, and calling
;              the appropriate operations.
; Receives: Nothing
; Returns: Nothing
;-----------------------------------------------------------------

main_loop PROC
    ; Display menu and get user choice
    call displayMenu
    lea eax, inputPrompt
    call print
    call getInput
    call toUpperCase
    mov userChoice, al
    call WriteChar
    call crlf

    ; Handle memory recall option
    cmp userChoice, 'R'
    je recallMemory
    cmp userChoice, 'r'
    je recallMemory

    ; Handle assignment operation
    cmp userChoice, '='
    je assignment

    ; Get operands (only once)
    call getOperands

    ; Determine operation
    cmp userChoice, 'A'
    je addition
    cmp userChoice, 'a'
    je addition
    cmp userChoice, 'S'
    je subtraction
    cmp userChoice, 's'
    je subtraction
    cmp userChoice, 'M'                      
    je multiplicationOperation
    cmp userChoice, 'm'
    je multiplicationOperation
    cmp userChoice, 'D'
    je divisonOperation
    cmp userChoice, 'd'
    je divisonOperation
    cmp userChoice, '%'
    je moduloOperation

    ; Handle invalid choice
    lea eax, invalidChoice
    call print
    jmp main_loop                  ; Return to menu
    ; Handle invalid choice
    lea eax, invalidChoice
    call print
    jmp main_loop                  ; Return to menu


multiplicationOperation:
    push [leftOperand]             ; Push left operand onto the stack
    push [rightOperand]            ; Push right operand onto the stack
    call multiplication            ; Perform multiplication
    add esp, 8                     ; Clean up stack
    jmp result                     ; Jump to result handling

divisonOperation:
    push [rightOperand]             ; Push left operand onto the stack
    push [leftOperand]            ; Push right operand onto the stack
    call division                  ; Perform division
    add esp, 8                     ; Clean up stack
    jmp result                     ; Jump to result handling

moduloOperation:
    push [rightOperand]             ; Push left operand onto the stack
    push [leftOperand]            ; Push right operand onto the stack
    call modulo                    ; Perform modulo operation
    add esp, 8                     ; Clean up stack
    jmp result                     ; Jump to result handling

main_loop ENDP

;-----------------------------------------------------------------
; Procedure: addition
; Description: Adds two operands and updates counters.
; Receives: leftOperand (EAX), rightOperand (EBX)
; Returns: Result in tempResult, updates counters
;-----------------------------------------------------------------
addition PROC
    mov eax, [leftOperand]         ; Load left operand into EAX
    mov ebx, [rightOperand]        ; Load right operand into EBX
    add eax, ebx                   ; Perform addition
    mov tempResult, eax            ; Store result
    inc dword ptr [addCount]
    inc dword ptr [opCount]
    jmp result                     ; Display result
addition ENDP
;-----------------------------------------------------------------
; Procedure: subtraction
; Description: Subtracts the second operand from the first.
; Receives: leftOperand (EAX), rightOperand (EBX)
; Returns: tempResult updated with the difference.
; Updates: Increments subCount and opCount.
;-----------------------------------------------------------------
subtraction PROC
    mov eax, [leftOperand]         ; Load left operand into EAX
    mov ebx, [rightOperand]        ; Load right operand into EBX
    sub eax, ebx                   ; Perform subtraction
    mov tempResult, eax            ; Store result
    inc dword ptr [subCount]
    inc dword ptr [opCount]
    jmp result                     ; Display result
subtraction ENDP
;-----------------------------------------------------------------
; Procedure: multiplication
; Description: Multiplies two operands using repeated addition.
; Receives: leftOperand (EAX), rightOperand (EBX)
; Returns: tempResult updated with the product.
; Updates: Increments mulCount and opCount.
;-----------------------------------------------------------------

multiplication PROC
    push ebp
    mov ebp, esp                  ; Set up the stack frame
    mov eax, [ebp+8]              ; Get leftOperand from stack
    mov ecx, [ebp+12]             ; Get rightOperand from stack
    xor edx, edx                  ; Clear the result register

    cmp ecx, 0                    ; If rightOperand is 0, result is 0
    je multiplicationDone

multiplyLoop:
    add edx, eax                  ; Add leftOperand to result
    loop multiplyLoop             ; Decrement ECX and repeat until 0

multiplicationDone:
    mov tempResult, edx           ; Store the result
    inc dword ptr [mulCount]      ; Increment multiplication count
    inc dword ptr [opCount]       ; Increment operation count
    pop ebp                       ; Restore previous stack frame
    ret
multiplication ENDP
;-----------------------------------------------------------------
; Procedure: division
; Description: Divides two operands, handles division by zero.
; Receives: leftOperand (EAX), rightOperand (EBX)
; Returns: Result in tempResult, updates counters
;-----------------------------------------------------------------
division PROC
    push ebp                       ; Stack frame setup
    mov ebp, esp

    push eax                       ; Save registers
    push edx
    push ebx

    mov eax, [ebp+8]               ; Load leftOperand (dividend) into EAX
    mov ebx, [ebp+12]              ; Load rightOperand (divisor) into EBX

    cmp ebx, 0                     ; Check for division by zero
    je divByZero                   ; Jump to error handler if divisor is zero

    cdq                            ; Extend EAX into EDX:EAX (for signed division)
    idiv ebx                       ; Perform division, EAX = quotient, EDX = remainder

    jo Overflow                    ; Check for overflow, handle if needed

    mov memoryResult, eax          ; Store the quotient in memoryResult
    add runningTotal, eax          ; Update running total
    mov tempResult, eax            ; Store result in tempResult

    ; Display the result
    lea edx, resultMsg             ; Load result message
    call WriteString               ; Display result message

    mov eax, [ebp+8]               ; Reload leftOperand for display
    call WriteInt                  ; Display leftOperand
    lea edx, divS                  ; Load '/' symbol
    call WriteString               ; Display '/'
    mov eax, [ebp+12]              ; Reload rightOperand for display
    call WriteInt                  ; Display rightOperand
    lea edx, equalS                ; Load '=' symbol
    call WriteString               ; Display '='
    mov eax, memoryResult          ; Load division result
    call WriteInt                  ; Display division result
    call Crlf                      ; Add a new line

    jmp done                       ; Skip error handling

divByZero:
    lea edx, errorMsg              ; Load division-by-zero error message
    call WriteString               ; Display error message
    call Crlf                      ; Add a new line
    jmp done                       ; Skip further processing

Overflow:
    lea edx, overflowMsg           ; Load overflow error message
    call WriteString               ; Display overflow message
    call Crlf                      ; Add a new line

done:
    pop ebx                        ; Restore registers
    pop edx
    pop eax
    pop ebp                        ; Restore stack frame
    ret
division ENDP
;-----------------------------------------------------------------
; Procedure: modulo
; Description: Computes the remainder of the division of two operands.
;              Handles division by zero.
; Receives: leftOperand (EAX), rightOperand (EBX)
; Returns: tempResult updated with the remainder.
; Updates: Increments modCount and opCount.
;-----------------------------------------------------------------
modulo PROC
    push ebp
    mov ebp, esp

    push eax                       ; Save registers
    push edx
    push ebx

    mov eax, [ebp+8]               ; Load leftOperand (dividend) into EAX
    mov ebx, [ebp+12]              ; Load rightOperand (divisor) into EBX

    cmp ebx, 0                     ; Check for division by zero
    je handleError                 ; Redirect to error handler if zero

    cdq                            ; Extend EAX into EDX:EAX (for signed division)
    idiv ebx                       ; Perform division, EAX = quotient, EDX = remainder

    mov tempResult, edx            ; Store the remainder in tempResult
    inc dword ptr [modCount]       ; Increment modulo operation count
    inc dword ptr [opCount]        ; Increment total operations count

    ; Display the result
    lea edx, resultMsg
    call WriteString
    mov eax, [ebp+8]               ; Reload leftOperand for display
    call WriteInt
    lea edx, divS                  ; Load '/' symbol
    call WriteString
    mov eax, [ebp+12]              ; Reload rightOperand for display
    call WriteInt
    lea edx, equalS                ; Load '=' symbol
    call WriteString
    mov eax, tempResult            ; Load remainder
    call WriteInt                  ; Display result
    call Crlf                      ; Add a new line

    pop ebx                        ; Restore registers
    pop edx
    pop eax
    pop ebp
    ret
modulo ENDP
;-----------------------------------------------------------------
; Procedure: assignment
; Description: Assigns a user-specified integer value to a variable
;              (A-Z). Validates input, converts the variable name
;              to an array index, and stores the value in the
;              variables array.
; Receives: User input for variable name (A-Z) and integer value.
; Returns: Updates the specified variable in the variables array.
; Displays: Confirmation of the assignment (e.g., X = 2).
;------------------------------------------------------------------
assignment PROC
    ; Prompt the user for the variable to assign a value
    lea eax, enterFirstNum
    call print

    ; Get the variable input (A-Z)
    call getInput
    call WriteChar ; Debug: Print the variable input
    call Crlf
    cmp al, 'A'                 ; Check if input is below 'A'
    jb invalidChoiceHandler     ; Jump to invalid choice if invalid
    cmp al, 'Z'                 ; Check if input is above 'Z'
    ja invalidChoiceHandler     ; Jump to invalid choice if invalid

    ; Convert the variable (A-Z) to an array index (0-25)
    sub al, 'A'                 ; Subtract ASCII 'A' to get index
    movzx ecx, al               ; Store the index in ECX
    call WriteInt               ; Debug: Print variable index
    call Crlf

    ; Prompt for the value to assign
    lea eax, enterSecondNum
    call print
    call ReadInt                ; Read the integer value
    call WriteInt               ; Debug: Print the value read
    call Crlf

    ; Assign the value to the variable
    mov variables[ecx*4], eax   ; Store the value in the variables array
    call WriteInt               ; Debug: Verify the stored value
    call Crlf

    ; Display the assignment result (e.g., X = 2)
    mov al, 'A'                 ; Start with ASCII 'A'
    add al, cl                  ; Convert index back to the variable letter
    call WriteChar              ; Display the variable letter
    lea eax, equalS             ; Display " = "
    call WriteString
    mov eax, variables[ecx*4]   ; Load the assigned value
    call WriteInt               ; Display the value
    call Crlf                   ; New line

    ; Return to the main menu
    jmp main_loop
assignment ENDP

handleError PROC
    lea eax, errorMsg              ; Display error message
    call print
    mov [leftOperand], 0           ; Reset operands
    mov [rightOperand], 0
    jmp main_loop                  ; Return to main menu
handleError ENDP
;-----------------------------------------------------------------
; Procedure: recallMemory
; Description: Displays the current value stored in memoryResult.
; Receives: Nothing.
; Returns: Nothing.
;-----------------------------------------------------------------
recallMemory PROC
    ; Display the message for memory recall
    lea eax, memoryMsg
    call print

    ; Load the saved memory value
    mov eax, savedMem

    ; Print the recalled memory value
    call printNum

    ; Return to the main menu
    jmp main_loop
recallMemory ENDP
;-----------------------------------------------------------------
; Procedure: invalidChoiceHandler
; Description: Handles invalid user menu selections.
; Receives: Nothing.
; Returns: Displays invalid choice message and returns to main menu.
;-----------------------------------------------------------------
invalidChoiceHandler PROC
    lea eax, invalidChoice        ; Load the invalid choice message
    call print                    ; Print the invalid choice message
    jmp main_loop                 ; Redirect back to the main menu
invalidChoiceHandler ENDP
;-----------------------------------------------------------------
; Procedure: getOperands
; Description: Prompts the user to input two operands, validates them,
;              and stores them in leftOperand and rightOperand.
; Receives: User input for operands.
; Returns: Updated leftOperand and rightOperand.
; Handles: Division/modulo validation for non-zero divisor.
;-----------------------------------------------------------------
getOperands PROC
    ; Get left operand
    lea eax, enterFirstNum
    call print
    call getInput
    call validateOperand
    mov [leftOperand], eax

    ; Get right operand
    lea eax, enterSecondNum
    call print
    call getInput
    call validateOperand
    mov [rightOperand], eax

    ; Validate divisor if division or modulo operation
    cmp userChoice, 'D'
    je validateDivisor
    cmp userChoice, 'd'
    je validateDivisor
    cmp userChoice, '%'
    je validateDivisor

    ret

validateDivisor:
    cmp [rightOperand], 0           ; Ensure divisor is not zero
    je handleError                  ; Redirect to error handler if zero
    ret
getOperands ENDP
;-----------------------------------------------------------------
; Procedure: validateOperand
; Description: Validates the user's input as either a variable (A-Z)
;              or a direct number.
; Receives: User input.
; Returns: Validated operand in EAX.
;-----------------------------------------------------------------
validateOperand PROC
    ; Check if input is a variable (A-Z)
    cmp al, 'A'                    ; Compare input with 'A'
    jl notVariable                 ; If below 'A', jump to notVariable
    cmp al, 'Z'                    ; Compare input with 'Z'
    jg notVariable                 ; If above 'Z', jump to notVariable
    sub al, 'A'                    ; Convert ASCII 'A-Z' to an array index (0-25)
    movzx ecx, al                  ; Store index in ECX (zero-extended)
    mov eax, variables[ecx*4]      ; Load the value of the variable into EAX
    ret                            ; Return with the variable's value in EAX

notVariable:
    call ReadInt                   ; If not a variable, read it as a direct integer
    ret                            ; Return with the number in EAX
validateOperand ENDP
;-----------------------------------------------------------------
; Procedure: displayMenu
; Description: Displays the available operations menu to the user.
; Receives: Nothing.
; Returns: Nothing.
;-----------------------------------------------------------------

displayMenu PROC
    ; Display the main menu
    lea eax, menuMsg               ; Load the menu message header
    call print                     ; Print the menu message
    lea eax, menuOps               ; Load the list of operations
    call print                     ; Print the available operations
    ret                            ; Return to caller
displayMenu ENDP
;-----------------------------------------------------------------
; Procedure: displayReport
; Description: Displays a summary of the operations performed, including
;              total operations, running total, and average result.
; Receives: Nothing.
; Returns: Nothing.
;-----------------------------------------------------------------

displayReport PROC
    lea eax, finalReport
    call print
    lea eax, opCountMsg
    call print
    mov eax, opCount
    call printNum

    lea eax, sumMsg
    call print
    mov eax, runningTotal
    call printNum

    lea eax, avgMsg
    call print
    mov eax, runningTotal
    cdq
    idiv dword ptr [opCount]
    call printNum
    ret
displayReport ENDP
;-----------------------------------------------------------------
; Procedure: result
; Description: Displays the result of the last operation, stores it in
;              savedMem, and updates runningTotal. Prompts user for next
;              action.
; Receives: tempResult.
; Returns: Updated runningTotal and savedMem.
;-----------------------------------------------------------------

result PROC
    lea eax, resultMsg
    call print
    mov eax, tempResult
    mov savedMem, eax
    add runningTotal, eax
    call printNum

    ; Ask the user if they want to continue
    lea eax, exitPrompt
    call print
    call getInput
    cmp al, 'Y'                     ; Check if the user wants to continue
    je main_loop                    ; Jump to main_loop if Yes
    cmp al, 'y'
    je main_loop

    cmp al, 'N'                     ; Check if the user wants to exit
    je exitProgram                  ; Jump to exitProgram if No
    cmp al, 'n'
    je exitProgram

    ; Handle invalid input (force back to main loop)
    lea eax, invalidChoice
    call print
    jmp main_loop                   ; Redirect to main loop

exitProgram:
    ; Display the final report and exit
    call displayReport
    ret
result ENDP
;-----------------------------------------------------------------
; Procedure: waitForEnter
; Description: Waits for the user to press the Enter key before
;              proceeding.
; Receives: Nothing.
; Returns: Nothing.
;-----------------------------------------------------------------

waitForEnter PROC
    ; Wait for the user to press Enter
    call ReadChar                  ; Read a character (expects Enter key)
    ret
waitForEnter ENDP
;-----------------------------------------------------------------
; Procedure: print
; Description: Prints a null-terminated string and adds a newline.
; Receives: EAX with string address.
; Returns: Nothing.
;-----------------------------------------------------------------

print PROC
    push edx
    push eax
    mov edx, eax
    call WriteString
    call Crlf
    pop eax
    pop edx
    ret
print ENDP
;-----------------------------------------------------------------
; Procedure: printNum
; Description: Prints an integer and adds a newline.
; Receives: Integer in EAX.
; Returns: Nothing.
;-----------------------------------------------------------------

printNum PROC
    push eax
    push edx
    call WriteInt
    call Crlf
    pop edx
    pop eax
    ret
printNum ENDP
;-----------------------------------------------------------------
; Procedure: cls
; Description: Clears the console screen.
; Receives: Nothing.
; Returns: Nothing.
;-----------------------------------------------------------------

getInput PROC
    call ReadChar
    ret
getInput ENDP

cls PROC
    call Clrscr
    ret
cls ENDP
;-----------------------------------------------------------------
; Procedure: toUpperCase
; Description: Converts a lowercase ASCII character to uppercase.
; Receives: AL with input character.
; Returns: Converted character in AL.
;-----------------------------------------------------------------

toUpperCase PROC
    cmp al, 'a'   ;convert input into uppercase 
    jl noConvert
    cmp al, 'z'
    jg noConvert
    sub al, 32 
noConvert:
    ret
toUpperCase ENDP


END main