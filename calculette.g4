//malaubier_leo_21903309 pichard_aubin_21907677
grammar calculette;

@members {
   private int _cur_label = 1;
   /** générateur de nom d'étiquettes pour les boucles */
   private String getNewLabel() { return "Label" +(_cur_label++); }
   private TablesSymboles tablesSymboles = new TablesSymboles();
        }

start : calcul  EOF ;
calcul returns [ String code ]
@init{ $code = new String(); }   // On initialise code, pour l'utiliser comme accumulateur
@after{ System.out.println($code); } // On affiche l’ensemble du code produit

    :   (decl { $code += $decl.code; })*
        NEWLINE*

        (fonction { $code += $fonction.code; })* 
        NEWLINE*

        (instruction { $code += $instruction.code; })*

        { $code += "POP\n" + "  HALT\n"; }
    ;

instruction returns [ String code ]
    : expression finInstruction
        {
            $code = $expression.code + "RETURN \n";
        }
    | commentaire finInstruction
        {
          $code="";
        }
    | assignation finInstruction
        {
        	$code = $assignation.code;
        }

    | input finInstruction
        {
          $code = $input.code;
        }

    | print finInstruction
        {
          $code = $print.code;
        }

    | block finInstruction
        {
          $code = $block.code;
        }

    | condition finInstruction
        {
          $code = $condition.code;
        }

    | boucle finInstruction
        {
          $code = $boucle.code;
        }

    | operateursLogiques finInstruction
        {
          $code = $operateursLogiques.code;
        }

   | finInstruction
        {
            $code="";
        }
    ;

expression returns [ String code ]

    : '(' + a=expression ('*'|'*-'|'*+') b=expression + ')' {$code = $a.code + $b.code + "MUL\n";}
    | a=expression ('*'|'*-'|'*+') b=expression {$code = $a.code + $b.code + "MUL\n";}
    | '(' + a=expression ('/'|'/-'|'/+') b=expression + ')' {$code = $a.code + $b.code + "DIV\n";}
    | a=expression ('/'|'/-'|'/+') b=expression {$code = $a.code + $b.code + "DIV\n";}
    | '(' + a=expression '+' b=expression + ')' {$code = $a.code + $b.code + "ADD\n";}
    | a=expression '+' b=expression {$code = $a.code + $b.code + "ADD\n";}
    | '(' + a=expression ('-'|'-+'|'+-') b=expression + ')' {$code = $a.code + $b.code + "SUB\n";}
    | a=expression ('-'|'-+'|'+-') b=expression {$code = $a.code + $b.code + "SUB\n";}
    | ENTIER {$code = "PUSHI " + $ENTIER.int + "\n";}
    | IDENTIFIANT {
      VariableInfo vi = tablesSymboles.getVar($IDENTIFIANT.text);
            if(vi.address >= 0)
              // PUSHG : fait une copie sur le haut de la pile d'un élément
              $code = "PUSHG " + vi.address + "\n";
            else
              $code = "PUSHL " + vi.address + "\n";
          }
    | IDENTIFIANT '('args')' // appel de fonction
        {
          $code ="PUSHI 0\n";
        $code += $args.code+"CALL " + $IDENTIFIANT.text + "\n";
        for(int i=0;i<$args.size;i++){$code +="POP \n";}
        }
    ;

decl returns [ String code ]
    :
        TYPE IDENTIFIANT finInstruction
        {
            tablesSymboles.addVarDecl($IDENTIFIANT.text,$TYPE.text);
            $code = "PUSHI 0\n";
        }
    ;

assignation returns [ String code ]
    : IDENTIFIANT '=' expression
        {
            VariableInfo vi = tablesSymboles.getVar($IDENTIFIANT.text);
            $code = $expression.code + "STOREG " + vi.address + "\n";
        }
    | TYPE IDENTIFIANT '=' expression
        {
          tablesSymboles.addVarDecl($IDENTIFIANT.text,$TYPE.text);
          VariableInfo vi = tablesSymboles.getVar($IDENTIFIANT.text);
          $code = "PUSHI 0\n" + $expression.code  + "STOREG " + vi.address + "\n";

        }
    | IDENTIFIANT '+=' expression
      {
          VariableInfo vi = tablesSymboles.getVar($IDENTIFIANT.text);
          $code = "PUSHG " + vi.address + "\n" + $expression.code +  "ADD " + "\n" + "STOREG " + vi.address + "\n";
      }
    ;

input returns [String code]
    : 'input' + '(' + IDENTIFIANT + ')' + '=' + ENTIER
    {
      VariableInfo vi = tablesSymboles.getVar($IDENTIFIANT.text);
      $code = "PUSHI " + $ENTIER.int + "\n" + "STOREG " + vi.address + "\n";
    }
    | 'input' + '(' + IDENTIFIANT + ')'
    {
      VariableInfo vi = tablesSymboles.getVar($IDENTIFIANT.text);
      if (vi == null){
        tablesSymboles.addVarDecl($IDENTIFIANT.text,"int");
            $code = "PUSHI 0\n";
      }else{
      $code = "READ \n" + "STOREG " + vi.address + "\n";
      }
    }
    ;

print returns [String code]
    : 'print' + '(' IDENTIFIANT ')'
      {
        VariableInfo vi = tablesSymboles.getVar($IDENTIFIANT.text);
        {
          // STOREG : prend l'élément en haut de la pile pour le mettre quelque part
          $code = "PUSHG " + vi.address + "\n" + "WRITE \n" + "STOREG " + vi.address + "\n";
        }
      }
    | 'print' + '(' expression ')'
      {
        $code = $expression.code + "\n" + "WRITE \n";
      }
    ;

block returns [String code] @init{ $code = new String(); }
    : '{' instruction+ '}' + NEWLINE*
    {
      $code = $instruction.code;
    }
    ;

condition returns [String code]
    : 'true'  { $code = "  PUSHI 1\n"; }
    | 'false' { $code = "  PUSHI 0\n"; }
    | a=expression + '==' + b=expression
    {
      $code = $a.code + $b.code + "EQUAL" + "\n";
    //  System.out.println($a.code);
    //  System.out.println($b.code);
    }

    | a=expression + '!=' + b=expression
    {
      $code = $a.code + $b.code + "NEQ" + "\n";
    }

    | a=expression + '<>' + b=expression
    {
      $code = $a.code + $b.code + "NEQ" + "\n";
    }

    | a=expression + '<' + b=expression
    {
      $code = $a.code + $b.code + "INF" + "\n";
    }

    | a=expression + '>' + b=expression
    {
      $code = $a.code + $b.code + "SUP" + "\n";
    }

    | a=expression + '<=' + b=expression
    {
      $code = $a.code + $b.code + "INFEQ" + "\n";
    }

    | a=expression + '>=' + b=expression
    {
      $code = $a.code + $b.code + "SUPEQ" + "\n";
    }
     | RETURN expression finInstruction    
        {
          VariableInfo vi = tablesSymboles.getVar("return");
          $code = $expression.code + "STOREL " + vi.address + "\n" + "RETURN\n";
        }
    
    ;

boucle returns [ String code ]
    : 'while' + '(' + condition + ')' + instruction
      {
        String first = getNewLabel();
        String next = getNewLabel();
        $code = "LABEL " + first + "\n" + $condition.code + "JUMPF " + next + "\n" + $instruction.code + "JUMP " + first + "\n" + "LABEL " + next + "\n";
      }
    | 'while' + '(' + condition + ')' + block
      {
        String first = getNewLabel();
        String next = getNewLabel();
        $code = "LABEL " + first + "\n" + $condition.code + "JUMPF " + next + "\n" + $block.code + "JUMP " + first + "\n" + "LABEL " + next + "\n";
      }
    | 'while' + '(' + operateursLogiques + ')' + instruction
      {
        String first = getNewLabel();
        String next = getNewLabel();
        $code = "LABEL " + first + "\n" + $operateursLogiques.code + "JUMPF " + next + "\n" + $instruction.code + "JUMP " + first + "\n" + "LABEL " + next + "\n";
      }
    | 'while' + '(' + operateursLogiques + ')' + block
      {
        String first = getNewLabel();
        String next = getNewLabel();
        $code = "LABEL " + first + "\n" + $operateursLogiques.code + "JUMPF " + next + "\n" + $block.code + "JUMP " + first + "\n" + "LABEL " + next + "\n";
      }
      ;

operateursLogiques returns [String code]
    // Marche pas quand deux conditions sont fausses
    : a=condition + '&&' + b=condition
    {
      $code = "PUSHI 1 \n" + $a.code + "EQUAL \n" + "PUSHI 1 \n" + $b.code + "EQUAL \n" + "EQUAL \n";
    }
    // Marche pas mais ne comprend pas pourquoi...
    | a=condition + '||' + b=condition
    {
      String next = getNewLabel();

      $code = "PUSHI 1 \n" + $a.code + "EQUAL \n" + "JUMPF " + next + "\n" + "PUSHI 1 \n" + $b.code + "EQUAL \n" +"LABEL " + next + "\n";

    }
    // Marche que quand la condition est différente mais positif
    | '!' + condition
    {
      String next = getNewLabel();
      String second = getNewLabel();

      $code = "PUSHI 0 \n" + $condition.code + "EQUAL \n" + "JUMPF " + next + "\n" + "PUSHI 1 \n" + $condition.code + "EQUAL \n" +"JUMPF "+second+"\n"+ "LABEL " + next + "\n" + "POP \n"+"PUSHI 1\n"+"JUMP end\n" +"LABEL"+second+"\n"+ "POP" + "PUSHI 0 \n"+"JUMP end\n"+ "LABEL end \n";
    }
    ;
// init nécessaire à cause du ? final et donc args peut être vide (mais $args sera non null)
args returns [ String code, int size]
@init{ $code = new String(); $size = 0; }
    : ( expression
      {
        $code += $expression.code;
        $size += 1;
      }
      ( ',' expression
      {
        $code += $expression.code;
        $size += 1;
      }
      )*
        )?
      ;

params
    : TYPE IDENTIFIANT
        {
          tablesSymboles.addParam($IDENTIFIANT.text,$TYPE.text); 
            // code java gérant une variable locale (arg0)
        }
        ( ',' TYPE IDENTIFIANT
            {
                tablesSymboles.addParam($IDENTIFIANT.text,$TYPE.text); 
                // code java gérant une variable locale (argi)
            }
        )*
    ;

fonction returns [ String code ]
@init{ tablesSymboles.enterFunction(); } // initie la table locale
@after{ tablesSymboles.exitFunction(); } // supprime la table locale
    : TYPE IDENTIFIANT  
        {
	    //  Enregistre le type de la fonction  
      tablesSymboles.addFunction($IDENTIFIANT.text,$TYPE.text);
      tablesSymboles.addVarDecl("return",$TYPE.text);
      $code = "LABEL " + $IDENTIFIANT.text + "\n";
	}
        '(' params ? ')' block 
        {
            // corps de la fonction
      
      $code += $block.code;

	    $code += "RETURN\n";  //  Return "de sécurité"      
        }
      NEWLINE*
    ;

commentaire : (COMMENTAIRE_MULTI | COMMENTAIRE_MONO);

finInstruction : ( NEWLINE | ';' | UNMATCH)+ ;

// lexer

NEWLINE : '\r'? '\n';
TYPE : 'int' | 'double';
ENTIER : ('0'..'9')+;
RETURN : 'return';

COMMENTAIRE_MONO : '%' .*? NEWLINE -> skip ;

COMMENTAIRE_MULTI : '/*' .*? '*/' -> skip ;

IDENTIFIANT : ('a'..'z' | 'A'..'Z' | '_')('a'..'z' | 'A'..'Z' | '_' | '0'..'9')*;

fragment
SEPARATEUR :  ~('\r')('//')*;

fragment
SPACE : (' ');

UNMATCH : . -> skip;

MUL : ('*'|'*-'|'*+');
DIV : ('/'|'/-'|'/+');
SUB : ('-'|'-+'|'+-');
ADD : '+';
/** commandes
export CLASSPATH=".:/usr/share/java/*:$CLASSPATH"
java org.antlr.v4.Tool calculette.g4
javac *.java
antlr4-grun calculette 'calcul' -gui


tp-compil-autocor calculette.g4 TablesSymboles.java TableSimple.java VariableInfo.java


java MVaPAssembler test.mvap
java CBaP -d test.mvap.cbap
**/