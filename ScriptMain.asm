# Definição de registradores e aliases
.eqv numero $s0
.eqv caractere $s1
.eqv digito $s2
.eqv indice_principal $t0
.eqv indice_auxiliar $t1
.eqv sinal $t2
.eqv pos_num $t8
.eqv pos_lista $t9
.eqv resto $s7

.data
arquivo_entrada:       .asciiz "C:/Users/danie/OneDrive/Documentos/AssemblyArquitetura/lista.txt"          
arquivo_saida:         .asciiz "C:/Users/danie/OneDrive/Documentos/AssemblyArquitetura/lista_ordenada.txt" 
buffer_entrada:        .space 1024                  
buffer_saida:          .space 1024                  
.align 2                                          
vetor_numeros:        .space 600                   
vetor_caracteres:     .space 1024
delimitador:          .asciiz ","                  

.text

    # --- Passo 1: Abrir e ler o arquivo lista.txt ---
    li $v0, 13                                 
    la $a0, arquivo_entrada                    
    li $a1, 0                                  
    syscall                                     
    move $t5, $v0                               

    # Ler o conteúdo do arquivo no buffer_entrada
    move $a0, $t5                              
    li $v0, 14                                 
    la $a1, buffer_entrada                     
    li $a2, 1024                               
    syscall                                     
    move indice_auxiliar, $v0                  

    # --- Passo 2: Transformar string em números inteiros ---
    li indice_principal, 0                      
    li indice_auxiliar, 0                       
    li $t3, 100                                 

loop_lista:                                    
    li numero, 0                                
    li sinal, 1                                 

loop_interno:                                  
    lb caractere, buffer_entrada(indice_principal)
    beqz caractere, armazena                   
    beq caractere, ',', armazena               
    beq caractere, '-', negativo               

converte:                                       
    sub digito, caractere, 0x30                
    mul $t3, numero, 10                         
    add numero, $t3, digito                     
    addi indice_principal, indice_principal, 1  
    j loop_interno                               

negativo:                                       
    li sinal, -1                                
    addi indice_principal, indice_principal, 1   
    j loop_interno                               

armazena:                                       
    mul numero, numero, sinal                   
    sw numero, vetor_numeros(indice_auxiliar)  
    addi indice_auxiliar, indice_auxiliar, 4    
    li sinal, 1                                  
    addi indice_principal, indice_principal, 1   

    # Se chegamos ao final da string, termina o loop
    beqz caractere, ordena                      
    blt indice_auxiliar, 400, loop_lista        

    # --- Passo 3: Ordenar os valores com Bubble Sort ---
ordena:                                         
    li $t4, 1                                   

bubble_sort_externo:                          
    li $t4, 0                                   
    la $t5, vetor_numeros                      
    li $t6, 400                                 

bubble_sort_interno:                          
    lw indice_principal, 0($t5)                
    lw indice_auxiliar, 4($t5)                 
    ble indice_principal, indice_auxiliar, proximo

    # Troca os números
    sw indice_auxiliar, 0($t5)                 
    sw indice_principal, 4($t5)                 
    li $t4, 1                                   

proximo:                                       
    addi $t5, $t5, 4                            
    sub $t6, $t6, 4                              
    bgtz $t6, bubble_sort_interno               

    bne $t4, 0, bubble_sort_externo             

    # --- Passo 4: Imprimir a lista ordenada ---
    li indice_principal, 0                      
    li $t4, 100                                 

imprimir_loop:                                  
    lw numero, vetor_numeros(indice_principal) 
    li $v0, 1                                    
    move $a0, numero                            
    syscall                                     

    # Imprime a vírgula, se não for o último número
    addi $t4, $t4, -1                            
    bgtz $t4, imprimir_delimitador             

    j imprimir_fim                              

imprimir_delimitador:                         
    li $v0, 11                                  
    li $a0, ','                                 
    syscall                                      

    addi indice_principal, indice_principal, 4   
    j imprimir_loop                             

imprimir_fim:                                  
    li $v0, 11                                  
    li $a0, '\n'                                
    syscall                                      

# --- Passo 5: Salvar o Vetor Ordenado em "lista_ordenada.txt" ---
    li pos_lista, 0                             
    li pos_num, 0                               

loop_inicio:                                    
    li sinal, 0                                 
    li indice_auxiliar, 0                       

verifica_sinal:                                 
    beq pos_num, 400, escrita                  
    lw numero, vetor_numeros(pos_num)         
    add pos_num, pos_num, 4                    
    bge numero, $zero, converte_digito        

    li sinal, 1                                 
    mul numero, numero, -1                      

converte_digito:                              
    move digito, numero                         

proximo_digito:                              
    li $t7, 10                                  
    div digito, $t7                             
    mfhi resto                                  
    mflo digito                                 
    add caractere, resto, 0x30                 
    sb caractere, buffer_saida(indice_auxiliar) 
    add indice_auxiliar, indice_auxiliar, 1     
    bnez digito, proximo_digito                 

    # Adiciona sinal negativo, se necessário
    beqz sinal, ordena_digitos                 
    li $t7, '-'                                 
    sb $t7, buffer_saida(indice_auxiliar)       
    add indice_auxiliar, indice_auxiliar, 1     

ordena_digitos:                                
    beqz indice_auxiliar, add_virgula           
    addi indice_auxiliar, indice_auxiliar, -1    
    lb caractere, buffer_saida(indice_auxiliar)   
    sb caractere, vetor_caracteres(pos_lista)    
    add pos_lista, pos_lista, 1                  
    j ordena_digitos                             

add_virgula:                                    
    beq pos_num, 400, escrita                   
    li $t7, ','                                  
    sb $t7, vetor_caracteres(pos_lista)        
    add pos_lista, pos_lista, 1                 
    j loop_inicio                                

escrita:                                       
    # Abre o arquivo para escrita
    li $v0, 13                                  
    la $a0, arquivo_saida                        
    li $a1, 1                                   
    syscall                                      

leitura:                                       
    move $s7, $v0                                
    li $v0, 15                                   
    move $a0, $s7                                
    la $a1, vetor_caracteres                     
    move $a2, pos_lista                          
    syscall                                      

    # Fecha o arquivo de saída
    li $v0, 16                                   
    move $a0, $s7                                
    syscall                                       

fim:                                            
    li $v0, 10                                   
    syscall                                       
