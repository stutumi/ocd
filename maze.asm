.data
    ####### Configuração do Labirinto  #######
        maze: .byte 'X','_','_','_','_'
              .byte '_','#','#','#','#'
              .byte '_','_','_','_','_'
              .byte '#','#','#','#','_'
              .byte '#','#','#','#','X'

        size: .word 5    #elementos por linha 

        elem: .word 25   #elementos na matriz

     visited: .byte 0:25 #visitados memset(0)
    ############################################

     newline: .byte '\n'
        
         pos: .word  0, -1 #(x, y-1)
              .word  0,  1 #(x, y+1)
              .word -1,  0 #(x-1, y)
              .word  1,  0 #(x+1, y)
       
        wall: .byte '#'
    walkable: .byte '_'
      walked: .byte 'o'
         end: .byte 'X'
     
     str_ori: .asciiz "Labirinto Original:\n\n"
     str_sol: .asciiz "Solução do Labirinto:\n\n"
      str_no: .asciiz "O Labirinto não possui solução.\n"
.text
    #macro para imprimir uma string, recebe o ponteiro da string como arg
    .macro print_str($arg)
        la $a0, $arg
        li $v0, 4 #print_string
        syscall
    .end_macro

    main:
        #exibe o labirinto original
        print_str(str_ori)
        jal print

        #chama dfs(0, 0)
        li $a0, 0
        li $a1, 0
        jal dfs

        #se o retorno for 0, não existe solução
        beqz $v0, solution_notfound

        #caso contrário, "maze" conterá a solucão
        j solution_found

    solution_found:
        print_str(str_sol)
        jal print
        j exit
    
    solution_notfound:
        print_str(str_no)
        j exit
   
    exit:
        li $v0, 10
        syscall

   #a0 = x => $s0
   #a1 = y => $s1
   dfs:
        #aloca espaço na pilha
        subu $sp, $sp, 32

        #salva o endereço de retorno da função
        sw $ra, 28($sp)   
        
        #salva os registradores que serão modificados pela função
        sw $s0, 24($sp)
        sw $s1, 20($sp)
        sw $s2, 16($sp)
        sw $s3, 12($sp)
        sw $s4,  8($sp)
        sw $s5,  4($sp)

        #salva x e y originais
        move $s0, $a0
        move $s1, $a1

        lw $t0, size #carrega o tamanho da linha
        
        #posição no array = x*n+y
        multu $a0, $t0
        mflo $t0
        addu $t0, $t0, $a1

        #visiteda (x,y)
        li $t1, 1
        sb $t1, visited($t0)


        li $s3, 0 #i = 0
    
    dfs_loop:
        beq $s3, 32, dfs_loop_end #repete o loop para 8 words, consumindo 2 por iteração

        #lê 2 inteiros, variação de x e y
        lw $t0,   pos($s3) #varx
        lw $t1, pos+4($s3) #vary
        
        addi $s3, $s3, 8 #i+=2

        #gera e salva o novox e novoy
        add $s4, $s0, $t0 #novox = x+varx
        add $s5, $s1, $t1 #novoy = y+vary

        #chama coord_check(novox, novoy)
        move $a0, $s4 #novox
        move $a1, $s5 #novoy
        jal coord_check

        #se retornar 0, ignora pois é uma coordenada inválida
        beqz $v0, dfs_loop

        #guarda a posicao (pos = x*n+y) da nova coordenada
        move $s2, $v0 
        
        #carrega nos registradores temporários os caracteres
        lb $t0, maze($s2)
        lb $t1, end
        lb $t2, walkable 

        #encontrou o caractere do fim, retorna true
        beq $t0, $t1, dfs_found
        
        #encontrou uma parede, ignora e passa para a próxima iteração
        bne $t0, $t2, dfs_loop
        
        #muda o maze[novox][novoy] para o caractere "walked"
        lb $t3, walked
        sb $t3, maze($s2)

        #chamada recursiva dfs(novox, novoy)
        move $a0, $s4
        move $a1, $s5
        jal dfs

        #se achou na chamada recursiva, retorna true
        bnez $v0, dfs_found

        #backtracking, como não achou nas chamadas recursivas pode remover o "walked" de maze[novox][novoy]
        #pois ele não faz parte de um caminho válido
        lb $t3, walkable
        sb $t3, maze($s2)

        #próxima iteração
        j dfs_loop

    dfs_loop_end:
        li $v0, 0 #retorna false
        j dfs_return

    dfs_found:
        li $v0, 1 #retorna true
  
    dfs_return:
        #carrega o endereço de retorno
        lw $ra, 28($sp)
        
        #carrega os registradores para os anteriores à chamada da função
        lw $s0, 24($sp)
        lw $s1, 20($sp)
        lw $s2, 16($sp)
        lw $s3, 12($sp)
        lw $s4,  8($sp)
        lw $s5,  4($sp)

        #decrementa a pilha
        addiu $sp, $sp, 32

        #pula para o endereço de retorno da função
        jr $ra

   #a0 = x
   #a1 = y
   coord_check:
        #salva o endereço de retorno da função
        subu $sp, $sp, 4
        sw $ra, 0($sp)

        #carrega o tamanho da linha do labirinto
        lw $t0, size

        #checa se o x,y tá dentro do range permitido
        bltz $a0, coord_invalid     #x < 0
        bltz $a1, coord_invalid     #y < 0
        bge $a0, $t0, coord_invalid #x >= size
        bge $a1, $t0, coord_invalid #y >= size

        #posição no array = x*n+y
        multu $a0, $t0
        mflo $t0
        addu $t0, $t0, $a1

        #checa se a posicao ja foi visitada
        lb $t1, visited($t0) 
        bgtz $t1, coord_invalid
        
    coord_valid:
        move $v0, $t0 #retorna o endereço da coordenada no maze
        j coord_end
    
    coord_invalid:
        li $v0 0 #define retorno como 0: inválido

    coord_end:
        #carrega o endereço de retorno da função e pula para ele
        lw $ra, 0($sp)
        addiu $sp, $sp, 4
        jr $ra
        

    print:
        #salva o endereço de retorno da função
        subu $sp, $sp, 4
        sw $ra, 0($sp)

        #prepara para impressão
        li $t0, 0    #i = 0
        lw $t2, elem #quantidade de elementos que serão impressos
        lw $t3, size #tamanho da linha
        
    print_loop:
        #se chegou no último elemento, acaba a impressão
        beq $t0, $t2, print_end #t2 = n*m
        
        #carrega um elemento do labirinto
        lb $t1, maze($t0)
        addi $t0, $t0, 1  #i++
        la $a0, ($t1)     #carrega o endereço para imprimir
        li $v0, 11        #print_char
        syscall

        #imprime newline ao fim de cada linha
        div $t0, $t3            #$t3 = n
        mfhi $t6                #mod = hi, div = lo
        bne $t6, 0, print_loop  #imprime o próximo elemento se não acabou a linha
        la $a0, newline         #caso tenha acabado a linha, imprime \n
        li $v0, 4
        syscall
        
        #próxima iteração
        j print_loop
        
    print_end:
        #imprime uma nova linha e retorna para o endereço de retorno da função
        la $a0, newline
        li $v0, 4
        syscall
        lw $ra, 0($sp)
        addiu $sp, $sp, 4
        jr $ra

