--
-- PostgreSQL database dump
--

-- Dumped from database version 10.0
-- Dumped by pg_dump version 10.0

-- Started on 2017-11-16 06:04:35

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

DROP DATABASE login;
--
-- TOC entry 2858 (class 1262 OID 16522)
-- Name: login; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE login WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'English_United States.1252' LC_CTYPE = 'English_United States.1252';


ALTER DATABASE login OWNER TO postgres;

\connect login

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 1 (class 3079 OID 12924)
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- TOC entry 2861 (class 0 OID 0)
-- Dependencies: 1
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- TOC entry 2 (class 3079 OID 16537)
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- TOC entry 2862 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


SET search_path = public, pg_catalog;

--
-- TOC entry 204 (class 1255 OID 16607)
-- Name: proc_u_insert(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION proc_u_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
    -- Hash the password with a newly generated salt
    -- crypt() will store the hash and salt (and the algorithm and iterations) in the column
    new.salt_hash := crypt(new.salt_hash, gen_salt('bf', 8));
  return new;
end
$$;


ALTER FUNCTION public.proc_u_insert() OWNER TO postgres;

--
-- TOC entry 235 (class 1255 OID 16608)
-- Name: proc_u_update(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION proc_u_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  -- Only hash a new password if updating a password that is not blank or null
  if new.salt_hash != '' AND new.salt_hash != NULL then
    -- If the query specifies a password to update call crypt on the new password
    -- which should be plaintext.  Crypt stores the salt and the hash (and algorithm used)
    -- so when called it will extract the salt from the previous password and use
    -- the existing salt to hash the new password.
    new.salt_hash := crypt(new.salt_hash, new.pass_salt);
  else
    -- Otherwise if there was no password specified use the old one
    new.salt_hash := old.salt_hash;
  end if;
  return new;
end
$$;


ALTER FUNCTION public.proc_u_update() OWNER TO postgres;

--
-- TOC entry 215 (class 1255 OID 16578)
-- Name: users_hash_upsert(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION users_hash_upsert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  new.pass_hash := crypt(new.pass_hash, crypt(new.pass_hash, new.pass_salt));
  return new;
end
$$;


ALTER FUNCTION public.users_hash_upsert() OWNER TO postgres;

--
-- TOC entry 230 (class 1255 OID 16574)
-- Name: users_password_insert(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION users_password_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  new.pass := convert_to(crypt(convert_from(new.pass, 'LATIN1'), convert_from(new.salt, 'LATIN1')), 'LATIN1');
  return new;
end
$$;


ALTER FUNCTION public.users_password_insert() OWNER TO postgres;

--
-- TOC entry 199 (class 1259 OID 16611)
-- Name: u_userid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE u_userid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1
    CYCLE;


ALTER TABLE u_userid_seq OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 200 (class 1259 OID 16622)
-- Name: u; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE u (
    userid oid DEFAULT nextval('u_userid_seq'::regclass) NOT NULL,
    username character varying(30) NOT NULL,
    display character varying(60),
    is_admin boolean NOT NULL,
    salt_hash text NOT NULL
);


ALTER TABLE u OWNER TO postgres;

--
-- TOC entry 198 (class 1259 OID 16525)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE users (
    userid oid NOT NULL,
    username character varying(30) NOT NULL,
    display character varying(60),
    password character varying(64) NOT NULL,
    is_admin boolean NOT NULL,
    salt bytea NOT NULL,
    pass bytea NOT NULL,
    pass_hash text,
    pass_salt text
);


ALTER TABLE users OWNER TO postgres;

--
-- TOC entry 197 (class 1259 OID 16523)
-- Name: users_userid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE users_userid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE users_userid_seq OWNER TO postgres;

--
-- TOC entry 2863 (class 0 OID 0)
-- Dependencies: 197
-- Name: users_userid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE users_userid_seq OWNED BY users.userid;


--
-- TOC entry 2719 (class 2604 OID 16531)
-- Name: users userid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY users ALTER COLUMN userid SET DEFAULT nextval('users_userid_seq'::regclass);


--
-- TOC entry 2853 (class 0 OID 16622)
-- Dependencies: 200
-- Data for Name: u; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO u (userid, username, display, is_admin, salt_hash) VALUES (1, 'andrew', 'Andrew Prindle', true, '$2a$08$Or1OXHATQ.0wUoTSbU/JnuMhMILao9MU2aCB5uZB0/ELsLNC9qvji');
INSERT INTO u (userid, username, display, is_admin, salt_hash) VALUES (2, 'admin', 'Administrator', true, '$2a$08$UW3ta.wuNHbBamnEPLqlh.65VuU1HYOd4IZhjZQJdY1JoxM9JSMKm');
INSERT INTO u (userid, username, display, is_admin, salt_hash) VALUES (3, 'colexic', 'Coley Poley Oley', false, '$2a$08$beARJeX6W/CHKXQjLTwtUeE8b2VIHPkioP4Vd/gQMqrnlILNvntpO');


--
-- TOC entry 2851 (class 0 OID 16525)
-- Dependencies: 198
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO users (userid, username, display, password, is_admin, salt, pass, pass_hash, pass_salt) VALUES (2, 'andrew', 'Andrew Prindle', 'password', true, '\x24326124303624316c436f47614f73716d4f786c7a4e2f645275497065', '\x24326124303624316c436f47614f73716d4f786c7a4e2f645275497065672e5052535141494d6d433850724b48506f6b334269304674567a2e477379', '$2a$06$TF2wXunMzGeRaDVCv6fnUuFl8XqNv91gLjTFMyDuN4LvrcpcfMOby', '$2a$06$TF2wXunMzGeRaDVCv6fnUu');
INSERT INTO users (userid, username, display, password, is_admin, salt, pass, pass_hash, pass_salt) VALUES (1, 'admin', 'Administrator', '5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8', true, '\x243261243036244d654550752f76423658777579533950784c6c36612e', '\x243261243036244d654550752f76423658777579533950784c6c36612e62496f373333544b4550385462662e4f3653484150674a692e6d5662303779', '$2a$06$Z1L0z35zMwKWNk4ctedbbOrCppaJq43oL0c4pqfn3WeC6Q7eeDz4e', '$2a$06$Z1L0z35zMwKWNk4ctedbbO');


--
-- TOC entry 2864 (class 0 OID 0)
-- Dependencies: 199
-- Name: u_userid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('u_userid_seq', 3, true);


--
-- TOC entry 2865 (class 0 OID 0)
-- Dependencies: 197
-- Name: users_userid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('users_userid_seq', 3, true);


--
-- TOC entry 2724 (class 2606 OID 16630)
-- Name: u u_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY u
    ADD CONSTRAINT u_pkey PRIMARY KEY (userid);


--
-- TOC entry 2722 (class 2606 OID 16533)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (userid);


--
-- TOC entry 2725 (class 2620 OID 16575)
-- Name: users insert_users; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER insert_users BEFORE INSERT OR UPDATE ON users FOR EACH ROW EXECUTE PROCEDURE users_password_insert();


--
-- TOC entry 2727 (class 2620 OID 16631)
-- Name: u trigger_u_insert; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_u_insert BEFORE INSERT ON u FOR EACH ROW EXECUTE PROCEDURE proc_u_insert();


--
-- TOC entry 2728 (class 2620 OID 16632)
-- Name: u trigger_u_update; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_u_update BEFORE UPDATE ON u FOR EACH ROW EXECUTE PROCEDURE proc_u_update();


--
-- TOC entry 2726 (class 2620 OID 16579)
-- Name: users upsert_users; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER upsert_users BEFORE INSERT OR UPDATE ON users FOR EACH ROW EXECUTE PROCEDURE users_hash_upsert();


--
-- TOC entry 2860 (class 0 OID 0)
-- Dependencies: 7
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

GRANT ALL ON SCHEMA public TO PUBLIC;


-- Completed on 2017-11-16 06:04:35

--
-- PostgreSQL database dump complete
--
