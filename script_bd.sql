-- =====================================================
-- PROJETO CLYVO VET - SCRIPT COMPLETO - SPRINT 3
-- Mastering Relational and Non-Relational Database
-- Gustavo Barrios de Araujo | RM: 563358
-- Matheus Almeida Ribeiro  | RM: 562980
-- Phietro Solon Oliveira   | RM: 563842
--
-- Este script contem:
--  - Estrutura completa (tabelas + sequences) e carga de dados,
--    reaproveitando e corrigindo o codigo entregue na Sprint 2
--    (blocos de JOIN/GROUP BY e cursores explicitos ja incorporam
--    o feedback aplicado nos commits 6a3b4ed e a9ceb81, que
--    adicionaram o relatorio de consultas por veterinario e a
--    sumarizacao numerica/por especie).
--  - Duas novas funcoes (conversao manual para JSON e validacao
--    manual de CPF) exigidas na Sprint 3.
--  - Dois novos procedimentos (relatorio em JSON via JOIN e
--    relatorio de subtotais/total geral calculados manualmente).
--  - Uma trigger de auditoria (INSERT/UPDATE/DELETE) sobre PET.
-- =====================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;
SET LINESIZE 200;
SET PAGESIZE 200;

-- =====================================================
-- 1. LIMPEZA INICIAL (permite reexecutar o script do zero)
-- =====================================================

BEGIN
EXECUTE IMMEDIATE 'DROP TABLE TB_AUDITORIA CASCADE CONSTRAINTS PURGE';
EXECUTE IMMEDIATE 'DROP TABLE ALERTA CASCADE CONSTRAINTS PURGE';
EXECUTE IMMEDIATE 'DROP TABLE EXAME CASCADE CONSTRAINTS PURGE';
EXECUTE IMMEDIATE 'DROP TABLE MEDICAMENTO CASCADE CONSTRAINTS PURGE';
EXECUTE IMMEDIATE 'DROP TABLE VACINA CASCADE CONSTRAINTS PURGE';
EXECUTE IMMEDIATE 'DROP TABLE CONSULTA CASCADE CONSTRAINTS PURGE';
EXECUTE IMMEDIATE 'DROP TABLE VETERINARIO CASCADE CONSTRAINTS PURGE';
EXECUTE IMMEDIATE 'DROP TABLE PET CASCADE CONSTRAINTS PURGE';
EXECUTE IMMEDIATE 'DROP TABLE CLINICA CASCADE CONSTRAINTS PURGE';
EXECUTE IMMEDIATE 'DROP TABLE TUTOR CASCADE CONSTRAINTS PURGE';
EXECUTE IMMEDIATE 'DROP TABLE ERRO_LOG CASCADE CONSTRAINTS PURGE';
EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_ID_TUTOR';
EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_ID_PET';
EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_ID_CLINICA';
EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_ID_VETERINARIO';
EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_ID_CONSULTA';
EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_ID_VACINA';
EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_ID_MEDICAMENTO';
EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_ID_EXAME';
EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_ID_ALERTA';
EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_ID_LOG';
EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_ID_AUDITORIA';
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Nada para dropar: ' || SQLERRM);
END;
/

-- =====================================================
-- 2. SEQUENCES
-- =====================================================

CREATE SEQUENCE SEQ_ID_TUTOR START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE SEQ_ID_PET START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE SEQ_ID_CLINICA START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE SEQ_ID_VETERINARIO START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE SEQ_ID_CONSULTA START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE SEQ_ID_VACINA START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE SEQ_ID_MEDICAMENTO START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE SEQ_ID_EXAME START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE SEQ_ID_ALERTA START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE SEQ_ID_LOG START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE SEQ_ID_AUDITORIA START WITH 1 INCREMENT BY 1;

-- =====================================================
-- 3. TABELAS
-- =====================================================

CREATE TABLE TUTOR (
                       id_tutor NUMBER(10) PRIMARY KEY,
                       nome VARCHAR2(100) NOT NULL,
                       cpf VARCHAR2(14) UNIQUE NOT NULL,
                       email VARCHAR2(100) UNIQUE,
                       telefone VARCHAR2(20),
                       data_nascimento DATE,
                       endereco VARCHAR2(200)
);

CREATE TABLE PET (
                     id_pet NUMBER(10) PRIMARY KEY,
                     nome VARCHAR2(50) NOT NULL,
                     especie VARCHAR2(30) NOT NULL,
                     raca VARCHAR2(30),
                     data_nascimento DATE,
                     peso NUMBER(5,2),
                     sexo CHAR(1),
                     castrado CHAR(1) DEFAULT 'N',
                     id_tutor NUMBER(10) NOT NULL,
                     CONSTRAINT CK_PET_CASTRADO CHECK (castrado IN ('S', 'N')),
                     CONSTRAINT FK_PET_TUTOR FOREIGN KEY (id_tutor) REFERENCES TUTOR(id_tutor)
);

CREATE TABLE CLINICA (
                         id_clinica NUMBER(10) PRIMARY KEY,
                         nome VARCHAR2(100) NOT NULL,
                         cnpj VARCHAR2(18) UNIQUE NOT NULL,
                         email VARCHAR2(100) UNIQUE,
                         telefone VARCHAR2(20),
                         endereco VARCHAR2(200)
);

CREATE TABLE VETERINARIO (
                             id_veterinario NUMBER(10) PRIMARY KEY,
                             nome VARCHAR2(100) NOT NULL,
                             crmv VARCHAR2(20) UNIQUE NOT NULL,
                             especialidade VARCHAR2(50),
                             email VARCHAR2(100) UNIQUE,
                             telefone VARCHAR2(20),
                             id_clinica NUMBER(10) NOT NULL,
                             CONSTRAINT FK_VETERINARIO_CLINICA FOREIGN KEY (id_clinica) REFERENCES CLINICA(id_clinica)
);

CREATE TABLE CONSULTA (
                          id_consulta NUMBER(10) PRIMARY KEY,
                          data_hora TIMESTAMP NOT NULL,
                          tipo VARCHAR2(30) NOT NULL,
                          status VARCHAR2(20) NOT NULL,
                          observacoes VARCHAR2(500),
                          diagnostico VARCHAR2(500),
                          tratamento VARCHAR2(500),
                          id_pet NUMBER(10) NOT NULL,
                          id_veterinario NUMBER(10) NOT NULL,
                          CONSTRAINT FK_CONSULTA_PET FOREIGN KEY (id_pet) REFERENCES PET(id_pet),
                          CONSTRAINT FK_CONSULTA_VETERINARIO FOREIGN KEY (id_veterinario) REFERENCES VETERINARIO(id_veterinario)
);

CREATE TABLE VACINA (
                        id_vacina NUMBER(10) PRIMARY KEY,
                        nome VARCHAR2(50) NOT NULL,
                        data_aplicacao DATE NOT NULL,
                        data_proxima_dose DATE,
                        fabricante VARCHAR2(50),
                        lote VARCHAR2(30),
                        observacoes VARCHAR2(500),
                        id_pet NUMBER(10) NOT NULL,
                        CONSTRAINT FK_VACINA_PET FOREIGN KEY (id_pet) REFERENCES PET(id_pet)
);

CREATE TABLE MEDICAMENTO (
                             id_medicamento NUMBER(10) PRIMARY KEY,
                             nome VARCHAR2(50) NOT NULL,
                             dosagem VARCHAR2(50),
                             frequencia VARCHAR2(50),
                             data_inicio DATE NOT NULL,
                             data_fim DATE,
                             status VARCHAR2(20) DEFAULT 'ativo',
                             observacoes VARCHAR2(500),
                             id_pet NUMBER(10) NOT NULL,
                             id_consulta NUMBER(10),
                             CONSTRAINT FK_MEDICAMENTO_PET FOREIGN KEY (id_pet) REFERENCES PET(id_pet),
                             CONSTRAINT FK_MEDICAMENTO_CONSULTA FOREIGN KEY (id_consulta) REFERENCES CONSULTA(id_consulta)
);

CREATE TABLE EXAME (
                       id_exame NUMBER(10) PRIMARY KEY,
                       tipo VARCHAR2(50) NOT NULL,
                       data_realizacao DATE NOT NULL,
                       resultado VARCHAR2(1000),
                       url_arquivo VARCHAR2(500),
                       observacoes VARCHAR2(500),
                       id_pet NUMBER(10) NOT NULL,
                       id_consulta NUMBER(10),
                       CONSTRAINT FK_EXAME_PET FOREIGN KEY (id_pet) REFERENCES PET(id_pet),
                       CONSTRAINT FK_EXAME_CONSULTA FOREIGN KEY (id_consulta) REFERENCES CONSULTA(id_consulta)
);

CREATE TABLE ALERTA (
                        id_alerta NUMBER(10) PRIMARY KEY,
                        tipo VARCHAR2(30) NOT NULL,
                        mensagem VARCHAR2(500) NOT NULL,
                        data_geracao TIMESTAMP NOT NULL,
                        lido CHAR(1) DEFAULT 'N',
                        data_leitura TIMESTAMP,
                        id_pet NUMBER(10) NOT NULL,
                        CONSTRAINT CK_ALERTA_LIDO CHECK (lido IN ('S', 'N')),
                        CONSTRAINT FK_ALERTA_PET FOREIGN KEY (id_pet) REFERENCES PET(id_pet)
);

CREATE TABLE ERRO_LOG (
                          id_log NUMBER(10) PRIMARY KEY,
                          nome_procedure VARCHAR2(100),
                          usuario VARCHAR2(50),
                          data_erro DATE,
                          codigo_erro NUMBER,
                          mensagem_erro VARCHAR2(4000)
);

-- Tabela de auditoria exigida pela Sprint 3: registra toda operacao
-- de INSERT/UPDATE/DELETE realizada sobre PET, com valores antigos
-- e novos capturados via :OLD/:NEW pela trigger TRG_AUDITORIA_PET.
CREATE TABLE TB_AUDITORIA (
                              id_auditoria     NUMBER(10) PRIMARY KEY,
                              nome_usuario     VARCHAR2(50) NOT NULL,
                              tipo_operacao    VARCHAR2(10) NOT NULL,
                              data_hora        TIMESTAMP NOT NULL,
                              dados_anteriores VARCHAR2(1000),
                              dados_novos      VARCHAR2(1000),
                              CONSTRAINT CK_AUDITORIA_TIPO CHECK (tipo_operacao IN ('INSERT', 'UPDATE', 'DELETE'))
);

-- =====================================================
-- 4. FUNCOES
-- =====================================================

-- Valida se um nome tem conteudo e nao contem digitos numericos.
CREATE OR REPLACE FUNCTION FUN_VALIDA_NOME(p_nome VARCHAR2)
RETURN BOOLEAN
IS
    v_contador NUMBER := 0;
    v_caractere VARCHAR2(1);
BEGIN
    IF p_nome IS NULL OR LENGTH(p_nome) = 0 THEN
        RETURN FALSE;
END IF;

FOR v_contador IN 1..LENGTH(p_nome) LOOP
        v_caractere := SUBSTR(p_nome, v_contador, 1);
        IF v_caractere BETWEEN '0' AND '9' THEN
            RETURN FALSE;
END IF;
END LOOP;

RETURN TRUE;
END;
/

-- Valida se o nome de uma vacina foi informado.
CREATE OR REPLACE FUNCTION FUN_VALIDA_NOME_VACINA(p_nome VARCHAR2)
RETURN BOOLEAN
IS
BEGIN
    IF p_nome IS NULL OR LENGTH(p_nome) = 0 THEN
        RETURN FALSE;
END IF;
RETURN TRUE;
END;
/

-- ---------------------------------------------------------------
-- FUNCAO 2 (Sprint 3): substitui o processo de validacao de CPF do
-- projeto (antes o cadastro de TUTOR so garantia unicidade via
-- UNIQUE, sem checar se o numero e um CPF matematicamente valido).
-- Implementa manualmente o algoritmo de digito verificador (modulo
-- 11) usado pela Receita Federal, sem usar nenhuma funcao pronta de
-- validacao de documentos.
-- ---------------------------------------------------------------
CREATE OR REPLACE FUNCTION FUN_VALIDA_CPF(p_cpf IN VARCHAR2)
RETURN VARCHAR2
IS
    v_cpf              VARCHAR2(11) := '';
    v_char             VARCHAR2(1);
    v_primeiro_digito  NUMBER;
    v_soma             NUMBER;
    v_peso             NUMBER;
    v_digito1          NUMBER;
    v_digito2          NUMBER;
    v_todos_iguais     BOOLEAN;
    e_cpf_nulo         EXCEPTION;
    e_tamanho_invalido EXCEPTION;
    e_cpf_repetido     EXCEPTION;
BEGIN
    IF p_cpf IS NULL THEN
        RAISE e_cpf_nulo;
END IF;

    -- mantem somente os caracteres numericos (permite CPF digitado
    -- com pontos e traco, ex: 111.444.777-35)
FOR i IN 1..LENGTH(p_cpf) LOOP
        v_char := SUBSTR(p_cpf, i, 1);
        IF v_char BETWEEN '0' AND '9' THEN
            v_cpf := v_cpf || v_char;
END IF;
END LOOP;

    IF LENGTH(v_cpf) != 11 THEN
        RAISE e_tamanho_invalido;
END IF;

    -- CPFs com todos os digitos iguais (111.111.111-11 etc) nao sao
    -- validos mesmo que a conta do digito verificador feche
    v_primeiro_digito := TO_NUMBER(SUBSTR(v_cpf, 1, 1));
    v_todos_iguais := TRUE;
FOR i IN 2..11 LOOP
        IF TO_NUMBER(SUBSTR(v_cpf, i, 1)) != v_primeiro_digito THEN
            v_todos_iguais := FALSE;
END IF;
END LOOP;
    IF v_todos_iguais THEN
        RAISE e_cpf_repetido;
END IF;

    -- 1o digito verificador: soma ponderada (pesos de 10 a 2) dos
    -- 9 primeiros digitos, modulo 11
    v_soma := 0;
    v_peso := 10;
FOR i IN 1..9 LOOP
        v_soma := v_soma + TO_NUMBER(SUBSTR(v_cpf, i, 1)) * v_peso;
        v_peso := v_peso - 1;
END LOOP;
    v_digito1 := 11 - MOD(v_soma, 11);
    IF v_digito1 >= 10 THEN
        v_digito1 := 0;
END IF;

    -- 2o digito verificador: soma ponderada (pesos de 11 a 2) dos
    -- 10 primeiros digitos (9 originais + 1o digito), modulo 11
    v_soma := 0;
    v_peso := 11;
FOR i IN 1..10 LOOP
        v_soma := v_soma + TO_NUMBER(SUBSTR(v_cpf, i, 1)) * v_peso;
        v_peso := v_peso - 1;
END LOOP;
    v_digito2 := 11 - MOD(v_soma, 11);
    IF v_digito2 >= 10 THEN
        v_digito2 := 0;
END IF;

    IF v_digito1 = TO_NUMBER(SUBSTR(v_cpf, 10, 1))
       AND v_digito2 = TO_NUMBER(SUBSTR(v_cpf, 11, 1)) THEN
        RETURN 'VALIDO';
ELSE
        RETURN 'INVALIDO: digito verificador nao confere';
END IF;

EXCEPTION
    WHEN e_cpf_nulo THEN
        RETURN 'INVALIDO: CPF nao informado';
WHEN e_tamanho_invalido THEN
        RETURN 'INVALIDO: CPF deve conter 11 digitos numericos';
WHEN e_cpf_repetido THEN
        RETURN 'INVALIDO: CPF com digitos repetidos';
WHEN VALUE_ERROR THEN
        RETURN 'INVALIDO: CPF contem caracteres nao numericos';
WHEN OTHERS THEN
        RETURN 'INVALIDO: ' || SQLERRM;
END;
/

-- ---------------------------------------------------------------
-- FUNCAO 1 (Sprint 3): converte manualmente os dados relacionais de
-- um PET + seu TUTOR em uma string JSON, sem usar TO_JSON,
-- JSON_OBJECT ou qualquer funcao pronta de JSON do Oracle. A
-- montagem e feita por concatenacao de string, e aspas internas sao
-- escapadas manualmente (REPLACE e usado apenas como utilitario de
-- texto, nao como conversor de JSON).
-- ---------------------------------------------------------------
CREATE OR REPLACE FUNCTION FUN_MONTA_JSON_PET(
    p_id_pet      IN NUMBER,
    p_nome_pet    IN VARCHAR2,
    p_especie     IN VARCHAR2,
    p_raca        IN VARCHAR2,
    p_nome_tutor  IN VARCHAR2,
    p_email_tutor IN VARCHAR2
) RETURN VARCHAR2
IS
    v_nome_pet         VARCHAR2(200);
    v_raca             VARCHAR2(200);
    v_nome_tutor       VARCHAR2(200);
    v_json             VARCHAR2(1000);
    e_id_invalido      EXCEPTION;
    e_nome_obrigatorio EXCEPTION;
BEGIN
    IF p_id_pet IS NULL OR p_id_pet <= 0 THEN
        RAISE e_id_invalido;
END IF;

    IF p_nome_pet IS NULL OR LENGTH(p_nome_pet) = 0 THEN
        RAISE e_nome_obrigatorio;
END IF;

    -- escapa aspas duplas para nao quebrar a string JSON gerada
    v_nome_pet   := REPLACE(p_nome_pet, '"', '\"');
    v_raca       := REPLACE(NVL(p_raca, ''), '"', '\"');
    v_nome_tutor := REPLACE(NVL(p_nome_tutor, ''), '"', '\"');

    v_json := '{'
        || '"id_pet":' || TO_CHAR(p_id_pet) || ','
        || '"nome_pet":"' || v_nome_pet || '",'
        || '"especie":"' || NVL(p_especie, '') || '",'
        || '"raca":"' || v_raca || '",'
        || '"tutor":{'
            || '"nome":"' || v_nome_tutor || '",'
            || '"email":"' || NVL(p_email_tutor, '') || '"'
        || '}'
        || '}';

RETURN v_json;

EXCEPTION
    WHEN e_id_invalido THEN
        RETURN '{"erro":"id_pet invalido"}';
WHEN e_nome_obrigatorio THEN
        RETURN '{"erro":"nome do pet e obrigatorio"}';
WHEN VALUE_ERROR THEN
        RETURN '{"erro":"tipo de dado invalido ao montar JSON"}';
WHEN OTHERS THEN
        RETURN '{"erro":"' || REPLACE(SQLERRM, '"', '\"') || '"}';
END;
/

-- =====================================================
-- 5. TRIGGER DE AUDITORIA
-- Grava em TB_AUDITORIA toda operacao de INSERT, UPDATE ou DELETE
-- feita na tabela PET, com usuario, tipo de operacao, data/hora e os
-- valores antes/depois capturados via :OLD e :NEW.
-- =====================================================

CREATE OR REPLACE TRIGGER TRG_AUDITORIA_PET
AFTER INSERT OR UPDATE OR DELETE ON PET
    FOR EACH ROW
DECLARE
v_tipo_operacao VARCHAR2(10);
    v_dados_antigos VARCHAR2(1000);
    v_dados_novos   VARCHAR2(1000);
BEGIN
    IF INSERTING THEN
        v_tipo_operacao := 'INSERT';
        v_dados_antigos := NULL;
        v_dados_novos   := 'id_pet=' || :NEW.id_pet
            || ';nome=' || :NEW.nome
            || ';especie=' || :NEW.especie
            || ';raca=' || :NEW.raca
            || ';peso=' || :NEW.peso
            || ';id_tutor=' || :NEW.id_tutor;
    ELSIF UPDATING THEN
        v_tipo_operacao := 'UPDATE';
        v_dados_antigos := 'id_pet=' || :OLD.id_pet
            || ';nome=' || :OLD.nome
            || ';especie=' || :OLD.especie
            || ';raca=' || :OLD.raca
            || ';peso=' || :OLD.peso
            || ';id_tutor=' || :OLD.id_tutor;
        v_dados_novos := 'id_pet=' || :NEW.id_pet
            || ';nome=' || :NEW.nome
            || ';especie=' || :NEW.especie
            || ';raca=' || :NEW.raca
            || ';peso=' || :NEW.peso
            || ';id_tutor=' || :NEW.id_tutor;
    ELSIF DELETING THEN
        v_tipo_operacao := 'DELETE';
        v_dados_antigos := 'id_pet=' || :OLD.id_pet
            || ';nome=' || :OLD.nome
            || ';especie=' || :OLD.especie
            || ';raca=' || :OLD.raca
            || ';peso=' || :OLD.peso
            || ';id_tutor=' || :OLD.id_tutor;
        v_dados_novos := NULL;
END IF;

INSERT INTO TB_AUDITORIA (id_auditoria, nome_usuario, tipo_operacao, data_hora, dados_anteriores, dados_novos)
VALUES (SEQ_ID_AUDITORIA.NEXTVAL, USER, v_tipo_operacao, SYSTIMESTAMP, v_dados_antigos, v_dados_novos);
EXCEPTION
    WHEN OTHERS THEN
        -- a auditoria nunca deve impedir a operacao original em PET
        NULL;
END;
/

-- =====================================================
-- 6. PROCEDURE DE LOG DE ERROS
-- =====================================================

-- PRAGMA AUTONOMOUS_TRANSACTION: o COMMIT do log de erro precisa ser
-- isolado da transacao de quem chamou a procedure. Sem isso, o COMMIT
-- abaixo confirmaria (e limparia os SAVEPOINTs de) a transacao inteira
-- de quem invocou PRC_INSERE_LOG, o que quebraria qualquer ROLLBACK TO
-- SAVEPOINT feito depois por quem chamou (como nos testes de excecao
-- da secao 14 deste script).
CREATE OR REPLACE PROCEDURE PRC_INSERE_LOG(
    p_nome_procedure IN VARCHAR2,
    p_codigo_erro IN NUMBER,
    p_mensagem_erro IN VARCHAR2
)
IS
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
INSERT INTO ERRO_LOG (id_log, nome_procedure, usuario, data_erro, codigo_erro, mensagem_erro)
VALUES (SEQ_ID_LOG.NEXTVAL, p_nome_procedure, USER, SYSDATE, p_codigo_erro, p_mensagem_erro);
COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        NULL;
END;
/

-- =====================================================
-- 7. PROCEDURES DE INSERT
-- =====================================================

-- PRC_INSERE_TUTOR (Sprint 3): agora tambem valida o CPF chamando
-- FUN_VALIDA_CPF antes de gravar, alem da validacao de nome ja
-- existente na Sprint 2.
CREATE OR REPLACE PROCEDURE PRC_INSERE_TUTOR(
    p_nome IN VARCHAR2,
    p_cpf IN VARCHAR2,
    p_email IN VARCHAR2,
    p_telefone IN VARCHAR2,
    p_data_nascimento IN DATE,
    p_endereco IN VARCHAR2,
    p_retorno OUT VARCHAR2
)
IS
    v_id_tutor NUMBER(10);
    v_status_cpf VARCHAR2(60);
BEGIN
    IF NOT FUN_VALIDA_NOME(p_nome) THEN
        p_retorno := 'ERRO: Nome deve ter mais de 3 caracteres e não conter números';
        RETURN;
END IF;

    v_status_cpf := FUN_VALIDA_CPF(p_cpf);
    IF v_status_cpf != 'VALIDO' THEN
        p_retorno := 'ERRO: ' || v_status_cpf;
        RETURN;
END IF;

    v_id_tutor := SEQ_ID_TUTOR.NEXTVAL;

INSERT INTO TUTOR (id_tutor, nome, cpf, email, telefone, data_nascimento, endereco)
VALUES (v_id_tutor, p_nome, p_cpf, p_email, p_telefone, p_data_nascimento, p_endereco);

COMMIT;
p_retorno := 'Tutor cadastrado com sucesso! ID: ' || v_id_tutor;

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        p_retorno := 'ERRO: CPF ou E-mail já cadastrado';
ROLLBACK;
PRC_INSERE_LOG('PRC_INSERE_TUTOR', SQLCODE, SQLERRM);
WHEN VALUE_ERROR THEN
        p_retorno := 'ERRO: Tipo de dado inválido';
ROLLBACK;
PRC_INSERE_LOG('PRC_INSERE_TUTOR', SQLCODE, SQLERRM);
WHEN OTHERS THEN
        p_retorno := 'ERRO: ' || SQLERRM;
ROLLBACK;
PRC_INSERE_LOG('PRC_INSERE_TUTOR', SQLCODE, SQLERRM);
END;
/

CREATE OR REPLACE PROCEDURE PRC_INSERE_PET(
    p_nome IN VARCHAR2,
    p_especie IN VARCHAR2,
    p_raca IN VARCHAR2,
    p_data_nascimento IN DATE,
    p_peso IN NUMBER,
    p_sexo IN CHAR,
    p_castrado IN CHAR,
    p_id_tutor IN NUMBER,
    p_retorno OUT VARCHAR2
)
IS
    v_id_pet NUMBER(10);
BEGIN
    IF NOT FUN_VALIDA_NOME(p_nome) THEN
        p_retorno := 'ERRO: Nome do pet deve ter mais de 3 caracteres e não conter números';
        RETURN;
END IF;

    v_id_pet := SEQ_ID_PET.NEXTVAL;

INSERT INTO PET (id_pet, nome, especie, raca, data_nascimento, peso, sexo, castrado, id_tutor)
VALUES (v_id_pet, p_nome, p_especie, p_raca, p_data_nascimento, p_peso, p_sexo, NVL(p_castrado, 'N'), p_id_tutor);

COMMIT;
p_retorno := 'Pet cadastrado com sucesso! ID: ' || v_id_pet;

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        p_retorno := 'ERRO: ID do pet já existe';
ROLLBACK;
PRC_INSERE_LOG('PRC_INSERE_PET', SQLCODE, SQLERRM);
WHEN VALUE_ERROR THEN
        p_retorno := 'ERRO: Tipo de dado inválido';
ROLLBACK;
PRC_INSERE_LOG('PRC_INSERE_PET', SQLCODE, SQLERRM);
WHEN OTHERS THEN
        p_retorno := 'ERRO: ' || SQLERRM;
ROLLBACK;
PRC_INSERE_LOG('PRC_INSERE_PET', SQLCODE, SQLERRM);
END;
/

CREATE OR REPLACE PROCEDURE PRC_INSERE_CLINICA(
    p_nome IN VARCHAR2,
    p_cnpj IN VARCHAR2,
    p_email IN VARCHAR2,
    p_telefone IN VARCHAR2,
    p_endereco IN VARCHAR2,
    p_retorno OUT VARCHAR2
)
IS
    v_id_clinica NUMBER(10);
BEGIN
    IF NOT FUN_VALIDA_NOME(p_nome) THEN
        p_retorno := 'ERRO: Nome da clínica deve ter mais de 3 caracteres e não conter números';
        RETURN;
END IF;

    v_id_clinica := SEQ_ID_CLINICA.NEXTVAL;

INSERT INTO CLINICA (id_clinica, nome, cnpj, email, telefone, endereco)
VALUES (v_id_clinica, p_nome, p_cnpj, p_email, p_telefone, p_endereco);

COMMIT;
p_retorno := 'Clínica cadastrada com sucesso! ID: ' || v_id_clinica;

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        p_retorno := 'ERRO: CNPJ ou E-mail já cadastrado';
ROLLBACK;
PRC_INSERE_LOG('PRC_INSERE_CLINICA', SQLCODE, SQLERRM);
WHEN VALUE_ERROR THEN
        p_retorno := 'ERRO: Tipo de dado inválido';
ROLLBACK;
PRC_INSERE_LOG('PRC_INSERE_CLINICA', SQLCODE, SQLERRM);
WHEN OTHERS THEN
        p_retorno := 'ERRO: ' || SQLERRM;
ROLLBACK;
PRC_INSERE_LOG('PRC_INSERE_CLINICA', SQLCODE, SQLERRM);
END;
/

CREATE OR REPLACE PROCEDURE PRC_INSERE_VETERINARIO(
    p_nome IN VARCHAR2,
    p_crmv IN VARCHAR2,
    p_especialidade IN VARCHAR2,
    p_email IN VARCHAR2,
    p_telefone IN VARCHAR2,
    p_id_clinica IN NUMBER,
    p_retorno OUT VARCHAR2
)
IS
    v_id_veterinario NUMBER(10);
BEGIN
    IF NOT FUN_VALIDA_NOME(p_nome) THEN
        p_retorno := 'ERRO: Nome do veterinário deve ter mais de 3 caracteres e não conter números';
        RETURN;
END IF;

    v_id_veterinario := SEQ_ID_VETERINARIO.NEXTVAL;

INSERT INTO VETERINARIO (id_veterinario, nome, crmv, especialidade, email, telefone, id_clinica)
VALUES (v_id_veterinario, p_nome, p_crmv, p_especialidade, p_email, p_telefone, p_id_clinica);

COMMIT;
p_retorno := 'Veterinário cadastrado com sucesso! ID: ' || v_id_veterinario;

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        p_retorno := 'ERRO: CRMV ou E-mail já cadastrado';
ROLLBACK;
PRC_INSERE_LOG('PRC_INSERE_VETERINARIO', SQLCODE, SQLERRM);
WHEN VALUE_ERROR THEN
        p_retorno := 'ERRO: Tipo de dado inválido';
ROLLBACK;
PRC_INSERE_LOG('PRC_INSERE_VETERINARIO', SQLCODE, SQLERRM);
WHEN OTHERS THEN
        p_retorno := 'ERRO: ' || SQLERRM;
ROLLBACK;
PRC_INSERE_LOG('PRC_INSERE_VETERINARIO', SQLCODE, SQLERRM);
END;
/

CREATE OR REPLACE PROCEDURE PRC_INSERE_CONSULTA(
    p_data_hora IN TIMESTAMP,
    p_tipo IN VARCHAR2,
    p_status IN VARCHAR2,
    p_observacoes IN VARCHAR2,
    p_diagnostico IN VARCHAR2,
    p_tratamento IN VARCHAR2,
    p_id_pet IN NUMBER,
    p_id_veterinario IN NUMBER,
    p_retorno OUT VARCHAR2
)
IS
    v_id_consulta NUMBER(10);
BEGIN
    v_id_consulta := SEQ_ID_CONSULTA.NEXTVAL;

INSERT INTO CONSULTA (id_consulta, data_hora, tipo, status, observacoes, diagnostico, tratamento, id_pet, id_veterinario)
VALUES (v_id_consulta, p_data_hora, p_tipo, p_status, p_observacoes, p_diagnostico, p_tratamento, p_id_pet, p_id_veterinario);

COMMIT;
p_retorno := 'Consulta cadastrada com sucesso! ID: ' || v_id_consulta;

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        p_retorno := 'ERRO: ID da consulta já existe';
ROLLBACK;
PRC_INSERE_LOG('PRC_INSERE_CONSULTA', SQLCODE, SQLERRM);
WHEN VALUE_ERROR THEN
        p_retorno := 'ERRO: Tipo de dado inválido';
ROLLBACK;
PRC_INSERE_LOG('PRC_INSERE_CONSULTA', SQLCODE, SQLERRM);
WHEN OTHERS THEN
        p_retorno := 'ERRO: ' || SQLERRM;
ROLLBACK;
PRC_INSERE_LOG('PRC_INSERE_CONSULTA', SQLCODE, SQLERRM);
END;
/

CREATE OR REPLACE PROCEDURE PRC_INSERE_VACINA(
    p_nome IN VARCHAR2,
    p_data_aplicacao IN DATE,
    p_data_proxima_dose IN DATE,
    p_fabricante IN VARCHAR2,
    p_lote IN VARCHAR2,
    p_observacoes IN VARCHAR2,
    p_id_pet IN NUMBER,
    p_retorno OUT VARCHAR2
)
IS
    v_id_vacina NUMBER(10);
BEGIN
    IF NOT FUN_VALIDA_NOME_VACINA(p_nome) THEN
        p_retorno := 'ERRO: Nome da vacina não pode ser vazio';
        RETURN;
END IF;

    v_id_vacina := SEQ_ID_VACINA.NEXTVAL;

INSERT INTO VACINA (id_vacina, nome, data_aplicacao, data_proxima_dose, fabricante, lote, observacoes, id_pet)
VALUES (v_id_vacina, p_nome, p_data_aplicacao, p_data_proxima_dose, p_fabricante, p_lote, p_observacoes, p_id_pet);

COMMIT;
p_retorno := 'Vacina cadastrada com sucesso! ID: ' || v_id_vacina;

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        p_retorno := 'ERRO: ID da vacina já existe';
ROLLBACK;
PRC_INSERE_LOG('PRC_INSERE_VACINA', SQLCODE, SQLERRM);
WHEN VALUE_ERROR THEN
        p_retorno := 'ERRO: Tipo de dado inválido';
ROLLBACK;
PRC_INSERE_LOG('PRC_INSERE_VACINA', SQLCODE, SQLERRM);
WHEN OTHERS THEN
        p_retorno := 'ERRO: ' || SQLERRM;
ROLLBACK;
PRC_INSERE_LOG('PRC_INSERE_VACINA', SQLCODE, SQLERRM);
END;
/

CREATE OR REPLACE PROCEDURE PRC_INSERE_MEDICAMENTO(
    p_nome IN VARCHAR2,
    p_dosagem IN VARCHAR2,
    p_frequencia IN VARCHAR2,
    p_data_inicio IN DATE,
    p_data_fim IN DATE,
    p_status IN VARCHAR2,
    p_observacoes IN VARCHAR2,
    p_id_pet IN NUMBER,
    p_id_consulta IN NUMBER,
    p_retorno OUT VARCHAR2
)
IS
    v_id_medicamento NUMBER(10);
BEGIN
    IF NOT FUN_VALIDA_NOME(p_nome) THEN
        p_retorno := 'ERRO: Nome do medicamento deve ter mais de 3 caracteres e não conter números';
        RETURN;
END IF;

    v_id_medicamento := SEQ_ID_MEDICAMENTO.NEXTVAL;

INSERT INTO MEDICAMENTO (id_medicamento, nome, dosagem, frequencia, data_inicio, data_fim, status, observacoes, id_pet, id_consulta)
VALUES (v_id_medicamento, p_nome, p_dosagem, p_frequencia, p_data_inicio, p_data_fim, NVL(p_status, 'ativo'), p_observacoes, p_id_pet, p_id_consulta);

COMMIT;
p_retorno := 'Medicamento cadastrado com sucesso! ID: ' || v_id_medicamento;

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        p_retorno := 'ERRO: ID do medicamento já existe';
ROLLBACK;
PRC_INSERE_LOG('PRC_INSERE_MEDICAMENTO', SQLCODE, SQLERRM);
WHEN VALUE_ERROR THEN
        p_retorno := 'ERRO: Tipo de dado inválido';
ROLLBACK;
PRC_INSERE_LOG('PRC_INSERE_MEDICAMENTO', SQLCODE, SQLERRM);
WHEN OTHERS THEN
        p_retorno := 'ERRO: ' || SQLERRM;
ROLLBACK;
PRC_INSERE_LOG('PRC_INSERE_MEDICAMENTO', SQLCODE, SQLERRM);
END;
/

CREATE OR REPLACE PROCEDURE PRC_INSERE_EXAME(
    p_tipo IN VARCHAR2,
    p_data_realizacao IN DATE,
    p_resultado IN VARCHAR2,
    p_url_arquivo IN VARCHAR2,
    p_observacoes IN VARCHAR2,
    p_id_pet IN NUMBER,
    p_id_consulta IN NUMBER,
    p_retorno OUT VARCHAR2
)
IS
    v_id_exame NUMBER(10);
BEGIN
    v_id_exame := SEQ_ID_EXAME.NEXTVAL;

INSERT INTO EXAME (id_exame, tipo, data_realizacao, resultado, url_arquivo, observacoes, id_pet, id_consulta)
VALUES (v_id_exame, p_tipo, p_data_realizacao, p_resultado, p_url_arquivo, p_observacoes, p_id_pet, p_id_consulta);

COMMIT;
p_retorno := 'Exame cadastrado com sucesso! ID: ' || v_id_exame;

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        p_retorno := 'ERRO: ID do exame já existe';
ROLLBACK;
PRC_INSERE_LOG('PRC_INSERE_EXAME', SQLCODE, SQLERRM);
WHEN VALUE_ERROR THEN
        p_retorno := 'ERRO: Tipo de dado inválido';
ROLLBACK;
PRC_INSERE_LOG('PRC_INSERE_EXAME', SQLCODE, SQLERRM);
WHEN OTHERS THEN
        p_retorno := 'ERRO: ' || SQLERRM;
ROLLBACK;
PRC_INSERE_LOG('PRC_INSERE_EXAME', SQLCODE, SQLERRM);
END;
/

CREATE OR REPLACE PROCEDURE PRC_INSERE_ALERTA(
    p_tipo IN VARCHAR2,
    p_mensagem IN VARCHAR2,
    p_data_geracao IN TIMESTAMP,
    p_lido IN CHAR,
    p_data_leitura IN TIMESTAMP,
    p_id_pet IN NUMBER,
    p_retorno OUT VARCHAR2
)
IS
    v_id_alerta NUMBER(10);
BEGIN
    v_id_alerta := SEQ_ID_ALERTA.NEXTVAL;

INSERT INTO ALERTA (id_alerta, tipo, mensagem, data_geracao, lido, data_leitura, id_pet)
VALUES (v_id_alerta, p_tipo, p_mensagem, p_data_geracao, NVL(p_lido, 'N'), p_data_leitura, p_id_pet);

COMMIT;
p_retorno := 'Alerta cadastrado com sucesso! ID: ' || v_id_alerta;

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        p_retorno := 'ERRO: ID do alerta já existe';
ROLLBACK;
PRC_INSERE_LOG('PRC_INSERE_ALERTA', SQLCODE, SQLERRM);
WHEN VALUE_ERROR THEN
        p_retorno := 'ERRO: Tipo de dado inválido';
ROLLBACK;
PRC_INSERE_LOG('PRC_INSERE_ALERTA', SQLCODE, SQLERRM);
WHEN OTHERS THEN
        p_retorno := 'ERRO: ' || SQLERRM;
ROLLBACK;
PRC_INSERE_LOG('PRC_INSERE_ALERTA', SQLCODE, SQLERRM);
END;
/

-- =====================================================
-- 8. PROCEDIMENTO 1 (Sprint 3)
-- Faz o JOIN entre PET e TUTOR e exibe cada registro em formato
-- JSON, montado manualmente atraves da FUN_MONTA_JSON_PET (Funcao
-- 1). Trata 3 excecoes distintas: ausencia de dados, valor invalido
-- e erro generico.
-- =====================================================

CREATE OR REPLACE PROCEDURE PRC_RELATORIO_JSON_PET_TUTOR
IS
    CURSOR c_pet_tutor IS
SELECT p.id_pet, p.nome AS nome_pet, p.especie, p.raca,
       t.nome AS nome_tutor, t.email AS email_tutor
FROM PET p
         JOIN TUTOR t ON p.id_tutor = t.id_tutor
ORDER BY p.id_pet;

v_json_objeto   VARCHAR2(1000);
    v_qtd_registros NUMBER;
    v_contador      NUMBER := 0;
    e_sem_dados     EXCEPTION;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== RELATORIO JSON: PETS E TUTORES (JOIN PET + TUTOR) ===');

SELECT COUNT(*) INTO v_qtd_registros
FROM PET p JOIN TUTOR t ON p.id_tutor = t.id_tutor;

IF v_qtd_registros = 0 THEN
        RAISE e_sem_dados;
END IF;

    DBMS_OUTPUT.PUT_LINE('[');

FOR reg IN c_pet_tutor LOOP
        v_contador := v_contador + 1;

        v_json_objeto := FUN_MONTA_JSON_PET(
            p_id_pet      => reg.id_pet,
            p_nome_pet    => reg.nome_pet,
            p_especie     => reg.especie,
            p_raca        => reg.raca,
            p_nome_tutor  => reg.nome_tutor,
            p_email_tutor => reg.email_tutor
        );

        IF v_contador < v_qtd_registros THEN
            DBMS_OUTPUT.PUT_LINE('  ' || v_json_objeto || ',');
ELSE
            DBMS_OUTPUT.PUT_LINE('  ' || v_json_objeto);
END IF;
END LOOP;

    DBMS_OUTPUT.PUT_LINE(']');
    DBMS_OUTPUT.PUT_LINE('Total de registros no JSON: ' || v_contador);

EXCEPTION
    WHEN e_sem_dados THEN
        DBMS_OUTPUT.PUT_LINE('ERRO: Nenhum registro encontrado para o relatorio PET/TUTOR');
        PRC_INSERE_LOG('PRC_RELATORIO_JSON_PET_TUTOR', -20001, 'Nenhum registro encontrado');
WHEN VALUE_ERROR THEN
        DBMS_OUTPUT.PUT_LINE('ERRO: Valor invalido ao montar o JSON - ' || SQLERRM);
        PRC_INSERE_LOG('PRC_RELATORIO_JSON_PET_TUTOR', SQLCODE, SQLERRM);
WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERRO: ' || SQLERRM);
        PRC_INSERE_LOG('PRC_RELATORIO_JSON_PET_TUTOR', SQLCODE, SQLERRM);
END;
/

-- =====================================================
-- 9. PROCEDIMENTO 2 (Sprint 3)
-- Le a tabela de fatos PET (categorias: especie e tutor; valor
-- numerico: peso) e calcula manualmente, com controle de quebra em
-- um unico cursor ordenado, os subtotais por combinacao completa de
-- categorias (especie + tutor), o subtotal por especie e o total
-- geral. Nao usa SUM/GROUP BY/ROLLUP/CUBE para o calculo -- toda a
-- soma e acumulada em variaveis PL/SQL dentro do proprio loop.
-- =====================================================

CREATE OR REPLACE PROCEDURE PRC_RELATORIO_PESO_POR_ESPECIE
IS
    CURSOR c_peso IS
SELECT p.especie, t.nome AS tutor_nome, p.peso
FROM PET p
         JOIN TUTOR t ON p.id_tutor = t.id_tutor
ORDER BY p.especie, t.nome, p.id_pet;

v_especie_anterior  PET.especie%TYPE := NULL;
    v_tutor_anterior    TUTOR.nome%TYPE := NULL;
    v_soma_combo        NUMBER := 0;
    v_soma_especie      NUMBER := 0;
    v_soma_geral        NUMBER := 0;
    v_primeiro_registro BOOLEAN := TRUE;
    v_qtd_registros     NUMBER;
    e_sem_dados         EXCEPTION;
    e_peso_invalido     EXCEPTION;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== RELATORIO DE PESO POR ESPECIE E TUTOR (SUBTOTAIS MANUAIS) ===');

SELECT COUNT(*) INTO v_qtd_registros FROM PET;
IF v_qtd_registros = 0 THEN
        RAISE e_sem_dados;
END IF;

    DBMS_OUTPUT.PUT_LINE(RPAD('ESPECIE', 13) || RPAD('TUTOR', 28) || LPAD('PESO(kg)', 10));
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 13, '-') || RPAD('-', 28, '-') || RPAD('-', 10, '-'));

FOR reg IN c_peso LOOP

        IF reg.peso IS NULL OR reg.peso <= 0 THEN
            RAISE e_peso_invalido;
END IF;

        IF v_primeiro_registro THEN
            v_especie_anterior  := reg.especie;
            v_tutor_anterior    := reg.tutor_nome;
            v_primeiro_registro := FALSE;
END IF;

        -- quebra de combinacao (especie+tutor mudou): fecha a linha
        -- da combinacao anterior antes de iniciar a nova
        IF reg.especie != v_especie_anterior OR reg.tutor_nome != v_tutor_anterior THEN
            DBMS_OUTPUT.PUT_LINE(RPAD(v_especie_anterior, 13) || RPAD(v_tutor_anterior, 28) || LPAD(TO_CHAR(v_soma_combo, '999999.99'), 10));
            v_soma_especie := v_soma_especie + v_soma_combo;
            v_soma_combo := 0;

            -- quebra de especie: fecha o subtotal da especie anterior
            IF reg.especie != v_especie_anterior THEN
                DBMS_OUTPUT.PUT_LINE(RPAD('Sub Total', 13) || RPAD(' ', 28) || LPAD(TO_CHAR(v_soma_especie, '999999.99'), 10));
                v_soma_geral := v_soma_geral + v_soma_especie;
                v_soma_especie := 0;
END IF;

            v_especie_anterior := reg.especie;
            v_tutor_anterior   := reg.tutor_nome;
END IF;

        v_soma_combo := v_soma_combo + reg.peso;
END LOOP;

    -- fecha a ultima combinacao, a ultima especie e o total geral
    -- apos o fim do loop (nao ha proxima linha para disparar a quebra)
    DBMS_OUTPUT.PUT_LINE(RPAD(v_especie_anterior, 13) || RPAD(v_tutor_anterior, 28) || LPAD(TO_CHAR(v_soma_combo, '999999.99'), 10));
    v_soma_especie := v_soma_especie + v_soma_combo;

    DBMS_OUTPUT.PUT_LINE(RPAD('Sub Total', 13) || RPAD(' ', 28) || LPAD(TO_CHAR(v_soma_especie, '999999.99'), 10));
    v_soma_geral := v_soma_geral + v_soma_especie;

    DBMS_OUTPUT.PUT_LINE(RPAD('-', 13, '-') || RPAD('-', 28, '-') || RPAD('-', 10, '-'));
    DBMS_OUTPUT.PUT_LINE(RPAD('Total Geral', 13) || RPAD(' ', 28) || LPAD(TO_CHAR(v_soma_geral, '999999.99'), 10));

EXCEPTION
    WHEN e_sem_dados THEN
        DBMS_OUTPUT.PUT_LINE('ERRO: Nao ha pets cadastrados para gerar o relatorio');
        PRC_INSERE_LOG('PRC_RELATORIO_PESO_POR_ESPECIE', -20002, 'Tabela PET vazia');
WHEN e_peso_invalido THEN
        DBMS_OUTPUT.PUT_LINE('ERRO: Peso invalido (nulo ou <= 0) encontrado no relatorio');
        PRC_INSERE_LOG('PRC_RELATORIO_PESO_POR_ESPECIE', -20003, 'Peso invalido encontrado durante o processamento');
WHEN VALUE_ERROR THEN
        DBMS_OUTPUT.PUT_LINE('ERRO: Valor invalido ao formatar numeros - ' || SQLERRM);
        PRC_INSERE_LOG('PRC_RELATORIO_PESO_POR_ESPECIE', SQLCODE, SQLERRM);
WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERRO: ' || SQLERRM);
        PRC_INSERE_LOG('PRC_RELATORIO_PESO_POR_ESPECIE', SQLCODE, SQLERRM);
END;
/


-- =====================================================
-- 10. INSERTS DE DADOS
-- CPFs validos (digito verificador correto) para que a validacao
-- feita por FUN_VALIDA_CPF dentro de PRC_INSERE_TUTOR seja aprovada.
-- =====================================================

DECLARE
v_retorno VARCHAR2(200);
BEGIN
    -- TUTORES
    PRC_INSERE_TUTOR('Ana Beatriz Oliveira', '11144477735', 'ana.oliveira@email.com', '(11) 98765-4321', TO_DATE('15/03/1985', 'DD/MM/YYYY'), 'Rua das Flores, 123 - Jardim Paulista - Sao Paulo/SP - 01234-567', v_retorno);
    PRC_INSERE_TUTOR('Carlos Eduardo Santos', '22255588846', 'carlos.santos@email.com', '(11) 97654-3210', TO_DATE('22/07/1990', 'DD/MM/YYYY'), 'Avenida Brasil, 456 - Centro - Rio de Janeiro/RJ - 20000-001', v_retorno);
    PRC_INSERE_TUTOR('Mariana Fernandes Souza', '33366699957', 'mariana.souza@email.com', '(31) 98765-1234', TO_DATE('10/11/1982', 'DD/MM/YYYY'), 'Rua Bahia, 789 - Savassi - Belo Horizonte/MG - 30100-002', v_retorno);
    PRC_INSERE_TUTOR('Roberto Almeida Lima', '44477700083', 'roberto.lima@email.com', '(41) 99876-5432', TO_DATE('05/02/1995', 'DD/MM/YYYY'), 'Rua XV de Novembro, 1010 - Batel - Curitiba/PR - 80000-003', v_retorno);
    PRC_INSERE_TUTOR('Fernanda Costa Rocha', '55588811194', 'fernanda.rocha@email.com', '(51) 97654-9876', TO_DATE('30/09/1988', 'DD/MM/YYYY'), 'Rua da Praia, 202 - Moinhos de Vento - Porto Alegre/RS - 90000-004', v_retorno);

    -- PETS
    PRC_INSERE_PET('Rex', 'Cao', 'Pastor Alemao', TO_DATE('20/08/2019', 'DD/MM/YYYY'), 32.0, 'M', 'S', 1, v_retorno);
    PRC_INSERE_PET('Luna', 'Cao', 'Golden Retriever', TO_DATE('15/03/2021', 'DD/MM/YYYY'), 22.0, 'F', 'N', 1, v_retorno);
    PRC_INSERE_PET('Mia', 'Gato', 'Siames', TO_DATE('05/01/2022', 'DD/MM/YYYY'), 4.5, 'F', 'S', 2, v_retorno);
    PRC_INSERE_PET('Nina', 'Roedor', 'Hamster', TO_DATE('10/02/2023', 'DD/MM/YYYY'), 0.08, 'F', 'N', 4, v_retorno);
    PRC_INSERE_PET('Billy', 'Cao', 'SRD', TO_DATE('25/12/2018', 'DD/MM/YYYY'), 18.5, 'M', 'S', 5, v_retorno);
    PRC_INSERE_PET('Jade', 'Reptil', 'Gecko', TO_DATE('03/07/2022', 'DD/MM/YYYY'), 0.05, 'F', 'N', 5, v_retorno);

    -- CLINICAS
    PRC_INSERE_CLINICA('Hospital Veterinario PetSaude', '12345678000190', 'contato@petsaude.com.br', '(11) 3456-7890', 'Av. Paulista, 1000 - Bela Vista - Sao Paulo/SP - 01310-100', v_retorno);
    PRC_INSERE_CLINICA('Clinica Veterinaria BemEstar', '23456789000101', 'contato@bemestar.vet', '(21) 3456-7891', 'Rua do Carmo, 200 - Centro - Rio de Janeiro/RJ - 20010-020', v_retorno);
    PRC_INSERE_CLINICA('Centro Veterinario Animal Feliz', '34567890000112', 'contato@animalfeliz.com', '(31) 3456-7892', 'Rua Paraiba, 500 - Savassi - Belo Horizonte/MG - 30130-140', v_retorno);
    PRC_INSERE_CLINICA('Clinica Veterinaria Vida Animal', '45678901000123', 'contato@vidaanimal.com.br', '(41) 3456-7893', 'Rua XV de Novembro, 1500 - Centro - Curitiba/PR - 80020-310', v_retorno);
    PRC_INSERE_CLINICA('Hospital Veterinario PatasUnidas', '56789012000134', 'contato@patasunidas.vet', '(51) 3456-7894', 'Av. Ipiranga, 800 - Azenha - Porto Alegre/RS - 90160-091', v_retorno);

    -- VETERINARIOS
    PRC_INSERE_VETERINARIO('Dra. Beatriz Mendes', 'CRMV-SP 12345', 'Clinica Geral', 'beatriz.mendes@vet.com', '(11) 98765-1234', 1, v_retorno);
    PRC_INSERE_VETERINARIO('Dr. Ricardo Alves', 'CRMV-SP 12346', 'Cirurgia', 'ricardo.alves@vet.com', '(11) 98765-5678', 1, v_retorno);
    PRC_INSERE_VETERINARIO('Dra. Carla Souza', 'CRMV-RJ 54321', 'Dermatologia', 'carla.souza@vet.com', '(21) 98765-4321', 2, v_retorno);
    PRC_INSERE_VETERINARIO('Dr. Fernando Lima', 'CRMV-MG 67890', 'Ortopedia', 'fernando.lima@vet.com', '(31) 98765-6789', 3, v_retorno);
    PRC_INSERE_VETERINARIO('Dra. Patricia Rocha', 'CRMV-PR 11223', 'Oftalmologia', 'patricia.rocha@vet.com', '(41) 98765-1122', 4, v_retorno);
    PRC_INSERE_VETERINARIO('Dr. Marcos Andrade', 'CRMV-RS 33445', 'Cardiologia', 'marcos.andrade@vet.com', '(51) 98765-3344', 5, v_retorno);
    PRC_INSERE_VETERINARIO('Dra. Juliana Costa', 'CRMV-RS 33446', 'Clinica Geral', 'juliana.costa@vet.com', '(51) 98765-5566', 5, v_retorno);

    -- CONSULTAS
    PRC_INSERE_CONSULTA(TO_TIMESTAMP('15/01/2024 10:30:00', 'DD/MM/YYYY HH24:MI:SS'), 'preventivo', 'concluida', 'Animal saudavel', 'Sem alteracoes', 'Manter rotina', 1, 1, v_retorno);
    PRC_INSERE_CONSULTA(TO_TIMESTAMP('20/02/2024 14:15:00', 'DD/MM/YYYY HH24:MI:SS'), 'emergencia', 'concluida', 'Vomito e diarreia', 'Gastroenterite', 'Medicacao', 2, 2, v_retorno);
    PRC_INSERE_CONSULTA(TO_TIMESTAMP('10/03/2024 09:00:00', 'DD/MM/YYYY HH24:MI:SS'), 'retorno', 'agendada', 'Pos-operatorio', 'Castracao', 'Repouso', 3, 3, v_retorno);
    PRC_INSERE_CONSULTA(TO_TIMESTAMP('05/04/2024 11:45:00', 'DD/MM/YYYY HH24:MI:SS'), 'preventivo', 'concluida', 'Check-up', 'Saudavel', 'Nenhum', 4, 4, v_retorno);
    PRC_INSERE_CONSULTA(TO_TIMESTAMP('18/05/2024 15:30:00', 'DD/MM/YYYY HH24:MI:SS'), 'continuidade', 'em andamento', 'Problema ocular', 'Conjuntivite', 'Colirio', 5, 5, v_retorno);
    PRC_INSERE_CONSULTA(TO_TIMESTAMP('22/06/2024 08:20:00', 'DD/MM/YYYY HH24:MI:SS'), 'preventivo', 'concluida', 'Primeira consulta', 'Saudavel', 'Orientacoes', 6, 6, v_retorno);
    PRC_INSERE_CONSULTA(TO_TIMESTAMP('01/07/2024 16:00:00', 'DD/MM/YYYY HH24:MI:SS'), 'emergencia', 'concluida', 'Corte na pata', 'Ferimento', 'Curativo', 1, 7, v_retorno);

    -- VACINAS
    PRC_INSERE_VACINA('V8', TO_DATE('15/01/2024', 'DD/MM/YYYY'), TO_DATE('15/01/2025', 'DD/MM/YYYY'), 'Zoetis', 'L123ABC', 'Aplicacao anual', 1, v_retorno);
    PRC_INSERE_VACINA('V10', TO_DATE('20/02/2024', 'DD/MM/YYYY'), TO_DATE('20/02/2025', 'DD/MM/YYYY'), 'MSD', 'L456DEF', 'Aplicacao anual', 2, v_retorno);
    PRC_INSERE_VACINA('Antirrabica', TO_DATE('10/03/2024', 'DD/MM/YYYY'), TO_DATE('10/03/2025', 'DD/MM/YYYY'), 'Zoetis', 'L789GHI', 'Contra raiva', 3, v_retorno);
    PRC_INSERE_VACINA('Febre Aftosa', TO_DATE('05/04/2024', 'DD/MM/YYYY'), TO_DATE('05/04/2025', 'DD/MM/YYYY'), 'Boehringer', 'L012JKL', 'Anual', 4, v_retorno);
    PRC_INSERE_VACINA('V8', TO_DATE('18/05/2024', 'DD/MM/YYYY'), TO_DATE('18/05/2025', 'DD/MM/YYYY'), 'MSD', 'L345MNO', 'Anual', 5, v_retorno);
    PRC_INSERE_VACINA('Reptil', TO_DATE('22/06/2024', 'DD/MM/YYYY'), TO_DATE('22/06/2025', 'DD/MM/YYYY'), 'VetBrand', 'L678PQR', 'Check-up', 6, v_retorno);

    -- MEDICAMENTOS
    PRC_INSERE_MEDICAMENTO('Antibiotico', '1 comprimido', '12/12h', TO_DATE('15/01/2024', 'DD/MM/YYYY'), TO_DATE('25/01/2024', 'DD/MM/YYYY'), 'concluido', 'Infeccao', 1, 1, v_retorno);
    PRC_INSERE_MEDICAMENTO('Anti-inflamatorio', '1 comprimido', '24/24h', TO_DATE('20/02/2024', 'DD/MM/YYYY'), TO_DATE('27/02/2024', 'DD/MM/YYYY'), 'concluido', 'Gastroenterite', 2, 2, v_retorno);
    PRC_INSERE_MEDICAMENTO('Analgesico', '0.5 ml', '8/8h', TO_DATE('10/03/2024', 'DD/MM/YYYY'), TO_DATE('17/03/2024', 'DD/MM/YYYY'), 'concluido', 'Dor pos-op', 3, 3, v_retorno);
    PRC_INSERE_MEDICAMENTO('Vitaminas', '2 gotas', '1x/dia', TO_DATE('05/04/2024', 'DD/MM/YYYY'), TO_DATE('05/05/2024', 'DD/MM/YYYY'), 'ativo', 'Suplementacao', 4, 4, v_retorno);
    PRC_INSERE_MEDICAMENTO('Colirio', '2 gotas', '8/8h', TO_DATE('18/05/2024', 'DD/MM/YYYY'), TO_DATE('25/05/2024', 'DD/MM/YYYY'), 'ativo', 'Conjuntivite', 5, 5, v_retorno);
    PRC_INSERE_MEDICAMENTO('Antiparasitario', '1 dose', 'Unica', TO_DATE('22/06/2024', 'DD/MM/YYYY'), NULL, 'concluido', 'Preventivo', 6, 6, v_retorno);

    -- EXAMES
    PRC_INSERE_EXAME('Hemograma', TO_DATE('16/01/2024', 'DD/MM/YYYY'), 'Normal', NULL, 'Rotina', 1, 1, v_retorno);
    PRC_INSERE_EXAME('Ultrassom', TO_DATE('21/02/2024', 'DD/MM/YYYY'), 'Gastrite', NULL, 'Confirmacao', 2, 2, v_retorno);
    PRC_INSERE_EXAME('Raio-X', TO_DATE('11/03/2024', 'DD/MM/YYYY'), 'Cicatrizacao', NULL, 'Pos-op', 3, 3, v_retorno);
    PRC_INSERE_EXAME('Check-up', TO_DATE('06/04/2024', 'DD/MM/YYYY'), 'Saudavel', NULL, 'Anual', 4, 4, v_retorno);
    PRC_INSERE_EXAME('Teste Lacrimal', TO_DATE('19/05/2024', 'DD/MM/YYYY'), 'Reduzida', NULL, 'Conjuntivite', 5, 5, v_retorno);
    PRC_INSERE_EXAME('Parasitologico', TO_DATE('23/06/2024', 'DD/MM/YYYY'), 'Negativo', NULL, 'Rotina', 6, 6, v_retorno);

    -- ALERTAS
    PRC_INSERE_ALERTA('vacina proxima', 'V8 do Rex vence em 30 dias', TO_TIMESTAMP('15/12/2024 08:00:00', 'DD/MM/YYYY HH24:MI:SS'), 'N', NULL, 1, v_retorno);
    PRC_INSERE_ALERTA('medicamento acabando', 'Antibiotico do Rex acabando', TO_TIMESTAMP('20/01/2024 10:00:00', 'DD/MM/YYYY HH24:MI:SS'), 'S', TO_TIMESTAMP('21/01/2024 14:30:00', 'DD/MM/YYYY HH24:MI:SS'), 1, v_retorno);
    PRC_INSERE_ALERTA('retorno pendente', 'Luna tem retorno pendente', TO_TIMESTAMP('25/02/2024 09:00:00', 'DD/MM/YYYY HH24:MI:SS'), 'N', NULL, 2, v_retorno);
    PRC_INSERE_ALERTA('check-up pendente', 'Mia com check-up pendente', TO_TIMESTAMP('01/04/2024 08:00:00', 'DD/MM/YYYY HH24:MI:SS'), 'N', NULL, 3, v_retorno);
    PRC_INSERE_ALERTA('vacina proxima', 'Febre Aftosa da Nina vence em 15 dias', TO_TIMESTAMP('20/03/2025 09:00:00', 'DD/MM/YYYY HH24:MI:SS'), 'N', NULL, 4, v_retorno);
    PRC_INSERE_ALERTA('medicamento acabando', 'Colirio do Billy acabando', TO_TIMESTAMP('22/05/2024 14:00:00', 'DD/MM/YYYY HH24:MI:SS'), 'N', NULL, 5, v_retorno);
    PRC_INSERE_ALERTA('retorno pendente', 'Jade tem retorno pendente', TO_TIMESTAMP('30/06/2024 10:30:00', 'DD/MM/YYYY HH24:MI:SS'), 'N', NULL, 6, v_retorno);
    PRC_INSERE_ALERTA('exame disponivel', 'Resultado do exame de Jade disponivel', TO_TIMESTAMP('25/06/2024 16:00:00', 'DD/MM/YYYY HH24:MI:SS'), 'N', NULL, 6, v_retorno);

    DBMS_OUTPUT.PUT_LINE('DADOS INSERIDOS COM SUCESSO!');
END;
/


-- =====================================================
-- 11. RELATORIOS DA SPRINT 2 (JOIN + GROUP BY + ORDER BY)
-- Mantidos e corrigidos conforme o feedback anterior: o bloco de
-- consultas por veterinario e a sumarizacao numerica/por especie
-- ja estao incorporados abaixo (ver commits 6a3b4ed e a9ceb81).
-- =====================================================

-- BLOCO 1
DECLARE
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== RELATORIO DE CONSULTAS POR PET ===');
    DBMS_OUTPUT.PUT_LINE('PET                 | TUTOR              | TOTAL CONSULTAS');
    DBMS_OUTPUT.PUT_LINE('--------------------|--------------------|----------------');

FOR reg IN (
        SELECT p.nome AS pet_nome, t.nome AS tutor_nome, COUNT(c.id_consulta) AS total_consultas
        FROM CONSULTA c
        JOIN PET p ON c.id_pet = p.id_pet
        JOIN TUTOR t ON p.id_tutor = t.id_tutor
        GROUP BY p.nome, t.nome
        ORDER BY total_consultas DESC, p.nome
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(RPAD(reg.pet_nome, 20) || ' | ' || RPAD(reg.tutor_nome, 18) || ' | ' || reg.total_consultas);
END LOOP;

    DBMS_OUTPUT.PUT_LINE(' ');
    DBMS_OUTPUT.PUT_LINE('=== RELATORIO DE CONSULTAS POR VETERINARIO ===');
    DBMS_OUTPUT.PUT_LINE('VETERINARIO         | CLINICA             | TOTAL CONSULTAS');
    DBMS_OUTPUT.PUT_LINE('--------------------|--------------------|----------------');

FOR reg IN (
        SELECT v.nome AS vet_nome, cl.nome AS clinica_nome, COUNT(c.id_consulta) AS total_consultas
        FROM CONSULTA c
        JOIN VETERINARIO v ON c.id_veterinario = v.id_veterinario
        JOIN CLINICA cl ON v.id_clinica = cl.id_clinica
        GROUP BY v.nome, cl.nome
        ORDER BY total_consultas DESC, v.nome
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(RPAD(reg.vet_nome, 20) || ' | ' || RPAD(reg.clinica_nome, 18) || ' | ' || reg.total_consultas);
END LOOP;
END;
/

-- BLOCO 2
DECLARE
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== RELATORIO DE MEDICAMENTOS ATIVOS POR PET ===');
    DBMS_OUTPUT.PUT_LINE('PET                 | ESPECIE         | MEDICAMENTOS ATIVOS');
    DBMS_OUTPUT.PUT_LINE('--------------------|-----------------|--------------------');

FOR reg IN (
        SELECT p.nome AS pet_nome, p.especie, COUNT(m.id_medicamento) AS total_ativos
        FROM MEDICAMENTO m
        JOIN PET p ON m.id_pet = p.id_pet
        WHERE m.status = 'ativo'
        GROUP BY p.nome, p.especie
        ORDER BY total_ativos DESC, p.nome
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(RPAD(reg.pet_nome, 18) || ' | ' || RPAD(reg.especie, 15) || ' | ' || reg.total_ativos);
END LOOP;
END;
/


-- ANTERIOR/ATUAL/PROXIMO

DECLARE
v_anterior VARCHAR2(20);
    v_atual VARCHAR2(20);
    v_proximo VARCHAR2(20);

CURSOR c_pet IS
SELECT id_pet, nome, TO_CHAR(peso, '999.99') AS peso_formatado
FROM PET
ORDER BY id_pet;

v_reg_anterior c_pet%ROWTYPE;
    v_reg_atual c_pet%ROWTYPE;
    v_reg_proximo c_pet%ROWTYPE;
    v_contador NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== RELATORIO PESO DOS PETS ===');
    DBMS_OUTPUT.PUT_LINE('ID  | NOME                 | ANTERIOR | ATUAL | PROXIMO');
    DBMS_OUTPUT.PUT_LINE('----|----------------------|----------|-------|---------');

FOR reg IN c_pet LOOP
        v_contador := v_contador + 1;
        v_reg_atual := reg;
        v_atual := v_reg_atual.peso_formatado;

        IF v_contador = 1 THEN
            v_anterior := 'Vazio';
ELSE
            v_anterior := v_reg_anterior.peso_formatado;
END IF;

BEGIN
SELECT id_pet, nome, TO_CHAR(peso, '999.99')
INTO v_reg_proximo
FROM (SELECT id_pet, nome, peso FROM PET WHERE id_pet > v_reg_atual.id_pet ORDER BY id_pet)
WHERE ROWNUM = 1;
v_proximo := v_reg_proximo.peso_formatado;
EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_proximo := 'Vazio';
END;

        DBMS_OUTPUT.PUT_LINE(LPAD(v_reg_atual.id_pet, 3) || ' | ' || RPAD(v_reg_atual.nome, 20) || ' | ' || RPAD(v_anterior, 8) || ' | ' || RPAD(v_atual, 5) || ' | ' || v_proximo);
        v_reg_anterior := v_reg_atual;
END LOOP;
END;
/


-- QUATRO BLOCOS COM CURSOR EXPLICITO

-- BLOCO 1 - Classificacao de peso + sumarizacao numerica + sumarizacao por especie
DECLARE
CURSOR c_pets IS SELECT id_pet, nome, especie, peso FROM PET ORDER BY id_pet;

CURSOR c_especie IS
SELECT especie, COUNT(*) AS qtd_pets, SUM(peso) AS peso_total, AVG(peso) AS peso_medio
FROM PET
GROUP BY especie
ORDER BY especie;

v_classificacao VARCHAR2(30);
    v_contador NUMBER := 0;
    v_peso_total_geral NUMBER;
    v_peso_medio_geral NUMBER;
    v_peso_max NUMBER;
    v_peso_min NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== CLASSIFICACAO DE PESO DOS PETS ===');
    DBMS_OUTPUT.PUT_LINE('ID  | NOME                 | ESPECIE      | PESO(kg) | CLASSIFICACAO');
    DBMS_OUTPUT.PUT_LINE('----|----------------------|--------------|----------|---------------');

FOR reg IN c_pets LOOP
        v_contador := v_contador + 1;
        IF reg.peso > 25 THEN v_classificacao := 'Acima do peso';
        ELSIF reg.peso BETWEEN 10 AND 25 THEN v_classificacao := 'Peso ideal';
        ELSIF reg.peso < 10 AND reg.peso > 0 THEN v_classificacao := 'Abaixo do peso';
ELSE v_classificacao := 'Nao classificado';
END IF;
        DBMS_OUTPUT.PUT_LINE(LPAD(reg.id_pet, 3) || ' | ' || RPAD(reg.nome, 20) || ' | ' || RPAD(reg.especie, 12) || ' | ' || LPAD(TO_CHAR(reg.peso, '999.99'), 7) || ' | ' || v_classificacao);
END LOOP;
    DBMS_OUTPUT.PUT_LINE('Total de pets analisados: ' || v_contador);

SELECT SUM(peso), AVG(peso), MAX(peso), MIN(peso)
INTO v_peso_total_geral, v_peso_medio_geral, v_peso_max, v_peso_min
FROM PET;

DBMS_OUTPUT.PUT_LINE(' ');
    DBMS_OUTPUT.PUT_LINE('=== DADOS NUMERICOS SUMARIZADOS (PESO) ===');
    DBMS_OUTPUT.PUT_LINE('Peso total : ' || TO_CHAR(v_peso_total_geral, '999.99') || ' kg');
    DBMS_OUTPUT.PUT_LINE('Peso medio : ' || TO_CHAR(v_peso_medio_geral, '999.99') || ' kg');
    DBMS_OUTPUT.PUT_LINE('Peso maximo: ' || TO_CHAR(v_peso_max, '999.99') || ' kg');
    DBMS_OUTPUT.PUT_LINE('Peso minimo: ' || TO_CHAR(v_peso_min, '999.99') || ' kg');

    DBMS_OUTPUT.PUT_LINE(' ');
    DBMS_OUTPUT.PUT_LINE('=== SUMARIZACAO DE PESO POR ESPECIE ===');
    DBMS_OUTPUT.PUT_LINE('ESPECIE       | QTD PETS | PESO TOTAL  | PESO MEDIO');
    DBMS_OUTPUT.PUT_LINE('--------------|----------|-------------|------------');
FOR reg IN c_especie LOOP
        DBMS_OUTPUT.PUT_LINE(RPAD(reg.especie, 13) || ' | ' || LPAD(reg.qtd_pets, 8) || ' | ' || LPAD(TO_CHAR(reg.peso_total, '999.99'), 11) || ' | ' || LPAD(TO_CHAR(reg.peso_medio, '999.99'), 10));
END LOOP;
END;
/

-- BLOCO 2 - Status das consultas
DECLARE
CURSOR c_consultas IS
SELECT c.id_consulta, c.tipo, c.status, p.nome AS pet_nome
FROM CONSULTA c JOIN PET p ON c.id_pet = p.id_pet ORDER BY c.id_consulta;
v_mensagem VARCHAR2(50);
    v_contador NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== STATUS DAS CONSULTAS ===');
    DBMS_OUTPUT.PUT_LINE('ID  | PET                  | TIPO          | STATUS     | ANALISE');
    DBMS_OUTPUT.PUT_LINE('----|----------------------|---------------|------------|------------------');

FOR reg IN c_consultas LOOP
        v_contador := v_contador + 1;
        IF reg.status = 'concluida' THEN v_mensagem := 'Atendimento finalizado';
        ELSIF reg.status = 'em andamento' THEN v_mensagem := 'Paciente em tratamento';
        ELSIF reg.status = 'agendada' THEN v_mensagem := 'Aguardando atendimento';
ELSE v_mensagem := 'Status desconhecido';
END IF;
        DBMS_OUTPUT.PUT_LINE(LPAD(reg.id_consulta, 3) || ' | ' || RPAD(reg.pet_nome, 20) || ' | ' || RPAD(reg.tipo, 13) || ' | ' || RPAD(reg.status, 10) || ' | ' || v_mensagem);
END LOOP;
    DBMS_OUTPUT.PUT_LINE('Total de consultas analisadas: ' || v_contador);
END;
/

-- BLOCO 3 - Vacinas por pet
DECLARE
CURSOR c_vacinas IS
SELECT p.nome AS pet_nome, COUNT(v.id_vacina) AS total_vacinas
FROM PET p LEFT JOIN VACINA v ON p.id_pet = v.id_pet
GROUP BY p.nome ORDER BY total_vacinas DESC;
v_classificacao VARCHAR2(30);
    v_contador NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== RELATORIO DE VACINAS POR PET ===');
    DBMS_OUTPUT.PUT_LINE('PET                 | TOTAL VACINAS | CLASSIFICACAO');
    DBMS_OUTPUT.PUT_LINE('--------------------|---------------|------------------');

FOR reg IN c_vacinas LOOP
        v_contador := v_contador + 1;
        IF reg.total_vacinas >= 2 THEN v_classificacao := 'Vacinacao em dia';
        ELSIF reg.total_vacinas = 1 THEN v_classificacao := 'Parcialmente vacinado';
ELSE v_classificacao := 'Sem vacinas';
END IF;
        DBMS_OUTPUT.PUT_LINE(RPAD(reg.pet_nome, 18) || ' | ' || LPAD(reg.total_vacinas, 11) || '       | ' || v_classificacao);
END LOOP;
    DBMS_OUTPUT.PUT_LINE('Total de pets analisados: ' || v_contador);
END;
/

-- BLOCO 4 - Sumarizacao e subtotais
DECLARE
CURSOR c_consultas IS
SELECT tipo, COUNT(*) AS total FROM CONSULTA GROUP BY tipo ORDER BY tipo;
v_total_geral NUMBER := 0;
    v_contador_tipos NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== RELATORIO DE CONSULTAS POR TIPO ===');
    DBMS_OUTPUT.PUT_LINE('TIPO              | TOTAL CONSULTAS');
    DBMS_OUTPUT.PUT_LINE('------------------|----------------');

FOR reg IN c_consultas LOOP
        v_contador_tipos := v_contador_tipos + 1;
        v_total_geral := v_total_geral + reg.total;
        DBMS_OUTPUT.PUT_LINE(RPAD(reg.tipo, 16) || ' | ' || LPAD(reg.total, 8));
END LOOP;

    DBMS_OUTPUT.PUT_LINE('------------------|----------------');
    DBMS_OUTPUT.PUT_LINE('TOTAL GERAL        | ' || LPAD(v_total_geral, 8));
    DBMS_OUTPUT.PUT_LINE('Total de tipos de consulta: ' || v_contador_tipos);
END;
/


-- =====================================================
-- 12. EXECUCAO DOS PROCEDIMENTOS DA SPRINT 3
-- =====================================================

EXEC PRC_RELATORIO_JSON_PET_TUTOR;
EXEC PRC_RELATORIO_PESO_POR_ESPECIE;


-- =====================================================
-- 13. DEMONSTRACAO DA TRIGGER DE AUDITORIA
-- Executa INSERT, UPDATE e DELETE em um pet de teste (sem
-- dependentes em outras tabelas) para disparar a trigger nas tres
-- situacoes e depois consulta o resultado gravado em TB_AUDITORIA.
-- =====================================================

DECLARE
v_id_toby PET.id_pet%TYPE;
BEGIN
    v_id_toby := SEQ_ID_PET.NEXTVAL;

    -- INSERT: dispara a trigger com dados novos (:NEW)
INSERT INTO PET (id_pet, nome, especie, raca, data_nascimento, peso, sexo, castrado, id_tutor)
VALUES (v_id_toby, 'Toby', 'Cao', 'Beagle', TO_DATE('01/01/2023', 'DD/MM/YYYY'), 12.0, 'M', 'N', 3);

-- UPDATE: dispara a trigger com dados antigos e novos (:OLD/:NEW)
UPDATE PET SET peso = 12.8 WHERE id_pet = v_id_toby;

-- DELETE: dispara a trigger com dados antigos (:OLD)
DELETE FROM PET WHERE id_pet = v_id_toby;

COMMIT;
DBMS_OUTPUT.PUT_LINE('Demonstracao da trigger de auditoria concluida (INSERT/UPDATE/DELETE em Toby).');
END;
/

COLUMN nome_usuario FORMAT A12
COLUMN tipo_operacao FORMAT A10
COLUMN data_hora FORMAT A19
COLUMN dados_anteriores FORMAT A45 WORD_WRAPPED
COLUMN dados_novos FORMAT A45 WORD_WRAPPED
SELECT id_auditoria, nome_usuario, tipo_operacao,
       TO_CHAR(data_hora, 'DD/MM/YYYY HH24:MI:SS') AS data_hora,
       dados_anteriores, dados_novos
FROM TB_AUDITORIA
ORDER BY id_auditoria;
CLEAR COLUMNS;


-- =====================================================
-- 14. DEMONSTRACAO DE TRATAMENTO DE EXCECOES
-- Cada bloco abaixo forca um cenario de erro diferente para provar
-- que as excecoes de cada funcao/procedimento estao sendo tratadas.
-- Os testes que alteram dados usam SAVEPOINT/ROLLBACK para nao
-- deixar nenhum residuo na base apos a execucao do script.
-- =====================================================

-- Funcao 2 (FUN_VALIDA_CPF): CPF nulo, tamanho invalido, digito
-- verificador incorreto e um caso valido para comparacao
DECLARE
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Teste FUN_VALIDA_CPF: CPF nulo ---');
    DBMS_OUTPUT.PUT_LINE(FUN_VALIDA_CPF(NULL));

    DBMS_OUTPUT.PUT_LINE('--- Teste FUN_VALIDA_CPF: tamanho invalido ---');
    DBMS_OUTPUT.PUT_LINE(FUN_VALIDA_CPF('123'));

    DBMS_OUTPUT.PUT_LINE('--- Teste FUN_VALIDA_CPF: digito verificador incorreto ---');
    DBMS_OUTPUT.PUT_LINE(FUN_VALIDA_CPF('11144477700'));

    DBMS_OUTPUT.PUT_LINE('--- Teste FUN_VALIDA_CPF: CPF valido ---');
    DBMS_OUTPUT.PUT_LINE(FUN_VALIDA_CPF('111.444.777-35'));
END;
/

-- Funcao 1 (FUN_MONTA_JSON_PET): id_pet invalido
DECLARE
v_json VARCHAR2(1000);
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Teste FUN_MONTA_JSON_PET: id_pet invalido ---');
    v_json := FUN_MONTA_JSON_PET(NULL, 'Teste', 'Cao', 'SRD', 'Tutor Teste', 'teste@email.com');
    DBMS_OUTPUT.PUT_LINE(v_json);
END;
/

-- PRC_INSERE_TUTOR: CPF duplicado, CPF invalido e nome invalido
DECLARE
v_retorno VARCHAR2(200);
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Teste PRC_INSERE_TUTOR: CPF duplicado ---');
    PRC_INSERE_TUTOR('Teste Duplicado', '11144477735', 'novo.teste@email.com', '(11) 90000-0000', SYSDATE, 'Endereco Teste', v_retorno);
    DBMS_OUTPUT.PUT_LINE(v_retorno);

    DBMS_OUTPUT.PUT_LINE('--- Teste PRC_INSERE_TUTOR: CPF invalido ---');
    PRC_INSERE_TUTOR('Teste CPF Invalido', '12345678900', 'teste.cpf@email.com', '(11) 90000-0001', SYSDATE, 'Endereco Teste', v_retorno);
    DBMS_OUTPUT.PUT_LINE(v_retorno);

    DBMS_OUTPUT.PUT_LINE('--- Teste PRC_INSERE_TUTOR: nome invalido (contem numero) ---');
    PRC_INSERE_TUTOR('Tutor123', '65432198712', 'teste.nome@email.com', '(11) 90000-0002', SYSDATE, 'Endereco Teste', v_retorno);
    DBMS_OUTPUT.PUT_LINE(v_retorno);
END;
/

-- PRC_INSERE_PET: tutor inexistente (viola a FK FK_PET_TUTOR -> WHEN OTHERS)
DECLARE
v_retorno VARCHAR2(200);
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Teste PRC_INSERE_PET: id_tutor inexistente (viola FK) ---');
    PRC_INSERE_PET('Rocky', 'Cao', 'SRD', SYSDATE, 15.0, 'M', 'N', 9999, v_retorno);
    DBMS_OUTPUT.PUT_LINE(v_retorno);
END;
/

-- PRC_INSERE_CLINICA: CNPJ duplicado (viola UNIQUE -> WHEN DUP_VAL_ON_INDEX)
DECLARE
v_retorno VARCHAR2(200);
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Teste PRC_INSERE_CLINICA: CNPJ duplicado ---');
    PRC_INSERE_CLINICA('Clinica Duplicada', '12345678000190', 'duplicada@email.com', '(11) 90000-0003', 'Endereco Teste', v_retorno);
    DBMS_OUTPUT.PUT_LINE(v_retorno);
END;
/

-- PRC_RELATORIO_PESO_POR_ESPECIE: forca peso invalido (<=0) e
-- desfaz a alteracao logo em seguida com ROLLBACK TO SAVEPOINT
DECLARE
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Teste PRC_RELATORIO_PESO_POR_ESPECIE: peso invalido ---');
SAVEPOINT sp_teste_peso;
UPDATE PET SET peso = -5 WHERE nome = 'Mia';
PRC_RELATORIO_PESO_POR_ESPECIE;
ROLLBACK TO sp_teste_peso;
END;
/

-- PRC_RELATORIO_JSON_PET_TUTOR: forca ausencia de dados esvaziando
-- temporariamente as tabelas dependentes de PET, e desfaz tudo com
-- ROLLBACK TO SAVEPOINT ao final (nenhum dado e perdido)
DECLARE
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Teste PRC_RELATORIO_JSON_PET_TUTOR: sem dados ---');
SAVEPOINT sp_teste_json;
DELETE FROM ALERTA;
DELETE FROM EXAME;
DELETE FROM MEDICAMENTO;
DELETE FROM VACINA;
DELETE FROM CONSULTA;
DELETE FROM PET;
PRC_RELATORIO_JSON_PET_TUTOR;
ROLLBACK TO sp_teste_json;
END;
/

-- Confirma que os dados originais continuam intactos apos os testes
-- de excecao (todos os testes acima usaram SAVEPOINT/ROLLBACK)
EXEC DBMS_OUTPUT.PUT_LINE('=== VERIFICACAO FINAL: RELATORIOS APOS OS TESTES DE EXCECAO ===');
EXEC PRC_RELATORIO_JSON_PET_TUTOR;
EXEC PRC_RELATORIO_PESO_POR_ESPECIE;

COLUMN nome_procedure FORMAT A30
COLUMN usuario FORMAT A12
COLUMN data_erro FORMAT A19
COLUMN mensagem_erro FORMAT A50 WORD_WRAPPED
SELECT nome_procedure, usuario, TO_CHAR(data_erro, 'DD/MM/YYYY HH24:MI:SS') AS data_erro, codigo_erro, mensagem_erro
FROM ERRO_LOG
ORDER BY id_log;
CLEAR COLUMNS;