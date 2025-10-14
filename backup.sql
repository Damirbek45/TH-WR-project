--
-- PostgreSQL database dump
--

\restrict XyxZlphAaME8FjMhQnbq7ep5FTfG6e1c3tnoiha2ICSQWtj2LRYZZzxMR3FOrMf

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: game_records(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.game_records(game_part text) RETURNS TABLE(game_title text, character_name text, difficulty_name text, player_name text, score bigint, record_date date)
    LANGUAGE sql
    AS $_$
SELECT
    g.title::text,
    c.character_name::text,
    d.difficulty_name::text,
    p.nickname::text,
    r.score::bigint,
    r.date::date
FROM records r
JOIN games g        ON r.game_id = g.game_id
JOIN characters c   ON r.character_id = c.character_id
JOIN difficulties d ON r.difficulty_id = d.difficulty_id
JOIN players p      ON r.player_id = p.player_id
WHERE g.title ILIKE '%' || $1 || '%'
ORDER BY
    (REGEXP_REPLACE(g.title, '[^0-9]', '', 'g'))::int,
    d.difficulty_id,
    c.character_name;
$_$;


ALTER FUNCTION public.game_records(game_part text) OWNER TO postgres;

--
-- Name: player_records(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.player_records(player_name text) RETURNS TABLE(game_title text, character_name text, difficulty_name text, score bigint, record_date date)
    LANGUAGE sql
    AS $_$
SELECT
    g.title::text AS game_title,
    c.character_name::text,
    d.difficulty_name::text,
    r.score::bigint,
    r.date::date
FROM records r
JOIN players p      ON r.player_id = p.player_id
JOIN games g        ON r.game_id = g.game_id
JOIN characters c   ON r.character_id = c.character_id
JOIN difficulties d ON r.difficulty_id = d.difficulty_id
WHERE p.nickname = $1
ORDER BY
    (REGEXP_REPLACE(g.title, '[^0-9]', '', 'g'))::int,
    d.difficulty_id,
    c.character_name;
$_$;


ALTER FUNCTION public.player_records(player_name text) OWNER TO postgres;

--
-- Name: update_rankings(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_rankings() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO rankings (player_id, global_rank, last_update)
        VALUES (NEW.player_id, NULL, CURRENT_DATE)
        ON CONFLICT (player_id) DO UPDATE
        SET last_update = CURRENT_DATE;
    ELSIF (TG_OP = 'UPDATE') THEN
        UPDATE rankings
        SET last_update = CURRENT_DATE
        WHERE player_id = NEW.player_id;
    ELSIF (TG_OP = 'DELETE') THEN
        UPDATE rankings
        SET last_update = CURRENT_DATE
        WHERE player_id = OLD.player_id;
    END IF;

    -- Счёт ранга(по очкам)
    WITH total_scores AS (
        SELECT 
            r.player_id,
            SUM(r.score) AS total_score
        FROM records r
        GROUP BY r.player_id
    ),
    ranked AS (
        SELECT 
            player_id,
            total_score,
            RANK() OVER (ORDER BY total_score DESC) AS rank_pos
        FROM total_scores
    )
    UPDATE rankings rk
    SET global_rank = ranked.rank_pos,
        last_update = CURRENT_DATE
    FROM ranked
    WHERE rk.player_id = ranked.player_id;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_rankings() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: characters; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.characters (
    character_id integer NOT NULL,
    game_id integer NOT NULL,
    character_name character varying(50) NOT NULL
);


ALTER TABLE public.characters OWNER TO postgres;

--
-- Name: characters_alt; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.characters_alt (
    alias_id integer NOT NULL,
    character_id integer NOT NULL,
    alias_name character varying(100) NOT NULL
);


ALTER TABLE public.characters_alt OWNER TO postgres;

--
-- Name: character_names; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.character_names AS
 SELECT characters.character_id,
    characters.character_name AS display_name
   FROM public.characters
UNION
 SELECT characters_alt.character_id,
    characters_alt.alias_name AS display_name
   FROM public.characters_alt;


ALTER VIEW public.character_names OWNER TO postgres;

--
-- Name: characters_character_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.characters_character_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.characters_character_id_seq OWNER TO postgres;

--
-- Name: characters_character_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.characters_character_id_seq OWNED BY public.characters.character_id;


--
-- Name: regions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.regions (
    region_id integer NOT NULL,
    region_name character varying(100) NOT NULL
);


ALTER TABLE public.regions OWNER TO postgres;

--
-- Name: countries_country_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.countries_country_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.countries_country_id_seq OWNER TO postgres;

--
-- Name: countries_country_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.countries_country_id_seq OWNED BY public.regions.region_id;


--
-- Name: difficulties; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.difficulties (
    difficulty_id integer NOT NULL,
    difficulty_name character varying(20) NOT NULL
);


ALTER TABLE public.difficulties OWNER TO postgres;

--
-- Name: difficulties_difficulty_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.difficulties_difficulty_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.difficulties_difficulty_id_seq OWNER TO postgres;

--
-- Name: difficulties_difficulty_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.difficulties_difficulty_id_seq OWNED BY public.difficulties.difficulty_id;


--
-- Name: games; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.games (
    game_id integer NOT NULL,
    title character varying(100) NOT NULL,
    release_year integer,
    CONSTRAINT games_release_year_check CHECK (((release_year >= 1995) AND ((release_year)::numeric <= EXTRACT(year FROM CURRENT_DATE))))
);


ALTER TABLE public.games OWNER TO postgres;

--
-- Name: games_game_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.games_game_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.games_game_id_seq OWNER TO postgres;

--
-- Name: games_game_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.games_game_id_seq OWNED BY public.games.game_id;


--
-- Name: players; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.players (
    player_id integer NOT NULL,
    nickname character varying(50) NOT NULL,
    region_id integer
);


ALTER TABLE public.players OWNER TO postgres;

--
-- Name: records; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.records (
    record_id integer NOT NULL,
    player_id integer NOT NULL,
    game_id integer NOT NULL,
    character_id integer NOT NULL,
    difficulty_id integer NOT NULL,
    score bigint NOT NULL,
    date date DEFAULT '1970-01-01'::date,
    CONSTRAINT records_score_check CHECK ((score >= 0))
);


ALTER TABLE public.records OWNER TO postgres;

--
-- Name: max_records; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.max_records AS
 SELECT g.title AS game_title,
    r.record_id,
    r.score,
    p.nickname AS player_name,
    c.character_name,
    d.difficulty_name,
    r.date
   FROM ((((public.records r
     JOIN public.games g ON ((r.game_id = g.game_id)))
     JOIN public.players p ON ((r.player_id = p.player_id)))
     JOIN public.characters c ON ((r.character_id = c.character_id)))
     JOIN public.difficulties d ON ((r.difficulty_id = d.difficulty_id)))
  WHERE (r.score = ( SELECT max(r2.score) AS max
           FROM public.records r2
          WHERE (r2.game_id = r.game_id)))
  ORDER BY (regexp_replace((g.title)::text, '[^0-9]'::text, ''::text, 'g'::text))::integer;


ALTER VIEW public.max_records OWNER TO postgres;

--
-- Name: players_player_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.players_player_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.players_player_id_seq OWNER TO postgres;

--
-- Name: players_player_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.players_player_id_seq OWNED BY public.players.player_id;


--
-- Name: rankings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.rankings (
    ranking_id integer NOT NULL,
    player_id integer NOT NULL,
    global_rank integer NOT NULL,
    last_update date DEFAULT CURRENT_DATE,
    CONSTRAINT rankings_global_rank_check CHECK ((global_rank > 0))
);


ALTER TABLE public.rankings OWNER TO postgres;

--
-- Name: rankings_ranking_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.rankings_ranking_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rankings_ranking_id_seq OWNER TO postgres;

--
-- Name: rankings_ranking_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.rankings_ranking_id_seq OWNED BY public.rankings.ranking_id;


--
-- Name: records_record_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.records_record_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.records_record_id_seq OWNER TO postgres;

--
-- Name: records_record_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.records_record_id_seq OWNED BY public.records.record_id;


--
-- Name: shottype_aliases_alias_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.shottype_aliases_alias_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.shottype_aliases_alias_id_seq OWNER TO postgres;

--
-- Name: shottype_aliases_alias_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.shottype_aliases_alias_id_seq OWNED BY public.characters_alt.alias_id;


--
-- Name: stage_runs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.stage_runs (
    record_id integer NOT NULL,
    stage_id integer NOT NULL,
    stage_score bigint NOT NULL,
    CONSTRAINT stage_runs_stage_score_check CHECK ((stage_score >= 0))
);


ALTER TABLE public.stage_runs OWNER TO postgres;

--
-- Name: stages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.stages (
    stage_id integer NOT NULL,
    game_id integer NOT NULL,
    stage_number integer NOT NULL,
    stage_name character varying(100)
);


ALTER TABLE public.stages OWNER TO postgres;

--
-- Name: stages_stage_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.stages_stage_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.stages_stage_id_seq OWNER TO postgres;

--
-- Name: stages_stage_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.stages_stage_id_seq OWNED BY public.stages.stage_id;


--
-- Name: characters character_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.characters ALTER COLUMN character_id SET DEFAULT nextval('public.characters_character_id_seq'::regclass);


--
-- Name: characters_alt alias_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.characters_alt ALTER COLUMN alias_id SET DEFAULT nextval('public.shottype_aliases_alias_id_seq'::regclass);


--
-- Name: difficulties difficulty_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.difficulties ALTER COLUMN difficulty_id SET DEFAULT nextval('public.difficulties_difficulty_id_seq'::regclass);


--
-- Name: games game_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.games ALTER COLUMN game_id SET DEFAULT nextval('public.games_game_id_seq'::regclass);


--
-- Name: players player_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.players ALTER COLUMN player_id SET DEFAULT nextval('public.players_player_id_seq'::regclass);


--
-- Name: rankings ranking_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rankings ALTER COLUMN ranking_id SET DEFAULT nextval('public.rankings_ranking_id_seq'::regclass);


--
-- Name: records record_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.records ALTER COLUMN record_id SET DEFAULT nextval('public.records_record_id_seq'::regclass);


--
-- Name: regions region_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.regions ALTER COLUMN region_id SET DEFAULT nextval('public.countries_country_id_seq'::regclass);


--
-- Name: stages stage_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stages ALTER COLUMN stage_id SET DEFAULT nextval('public.stages_stage_id_seq'::regclass);


--
-- Data for Name: characters; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.characters (character_id, game_id, character_name) FROM stdin;
1	1	Reimu A
2	1	Reimu B
3	1	Marisa A
4	1	Marisa B
5	2	Reimu A
6	2	Reimu B
7	2	Marisa A
8	2	Marisa B
9	2	Sakuya A
10	2	Sakuya B
11	3	Reimu & Yukari
12	3	Marisa & Alice
13	3	Sakuya & Remilia
14	3	Youmu & Yuyuko
15	3	Reimu
16	3	Yukari
17	3	Marisa
18	3	Alice
19	3	Sakuya
20	3	Remilia
21	3	Youmu
22	3	Yuyuko
23	4	Reimu
24	4	Marisa
25	4	Sakuya
26	4	Youmu
27	4	Reisen
28	4	Cirno
29	4	Lyrica
30	4	Mystia
31	4	Tewi
32	4	Aya
33	4	Medicine
34	4	Yuuka
35	4	Komachi
36	4	Eiki
37	5	Reimu A
38	5	Reimu B
39	5	Reimu C
40	5	Marisa A
41	5	Marisa B
42	5	Marisa C
43	6	Reimu A
44	6	Reimu B
45	6	Reimu C
46	6	Marisa A
47	6	Marisa B
48	6	Marisa C
49	7	Reimu A
50	7	Reimu B
51	7	Marisa A
52	7	Marisa B
53	7	Sanae A
54	7	Sanae B
55	8	Reimu
56	8	Marisa
57	8	Sanae
58	8	Youmu
59	9	Reimu A
60	9	Reimu B
61	9	Marisa A
62	9	Marisa B
63	9	Sakuya A
64	9	Sakuya B
65	10	Reimu
66	10	Marisa
67	10	Sanae
68	10	Reisen
69	11	Reimu Spring
70	11	Reimu Summer
71	11	Reimu Autumn
72	11	Reimu Winter
73	11	Marisa Spring
74	11	Marisa Summer
75	11	Marisa Autumn
76	11	Marisa Winter
77	11	Aya Spring
78	11	Aya Summer
79	11	Aya Autumn
80	11	Aya Winter
81	11	Cirno Spring
82	11	Cirno Summer
83	11	Cirno Autumn
84	11	Cirno Winter
85	12	Reimu Wolf
86	12	Reimu Otter
87	12	Reimu Eagle
88	12	Marisa Wolf
89	12	Marisa Otter
90	12	Marisa Eagle
91	12	Youmu Wolf
92	12	Youmu Otter
93	12	Youmu Eagle
94	13	Reimu
95	13	Marisa
96	13	Sanae
97	14	Reimu R1
98	14	Reimu R2
99	14	Reimu B1
100	14	Reimu B2
101	14	Reimu Y1
102	14	Reimu Y2
103	14	Reimu G1
104	14	Reimu G2
105	14	Marisa R1
106	14	Marisa R2
107	14	Marisa B1
108	14	Marisa B2
109	14	Marisa Y1
110	14	Marisa Y2
111	14	Marisa G1
112	14	Marisa G2
113	13	Sakuya
114	11	Reimu Extra
115	11	Cirno Extra
116	11	Aya Extra
117	11	Marisa Extra
\.


--
-- Data for Name: characters_alt; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.characters_alt (alias_id, character_id, alias_name) FROM stdin;
1	11	Border Team
2	12	Magic Team
3	13	Scarlet Team
4	14	Ghost Team
5	43	Reimu & Yukari
6	44	Reimu & Suika
7	45	Reimu & Aya
8	46	Marisa & Alice
9	47	Marisa & Patchouli
10	48	Marisa & Nitori
11	1	Reimu Homing
12	5	Reimu Homing
13	2	Reimu Needle
14	6	Reimu Needle
15	49	Reimu Needle
16	50	Reimu Homing
17	3	Marisa Missile
18	7	Marisa Missile
19	4	Marisa Laser
20	8	Marisa Laser
21	51	Marisa Laser
22	52	Marisa Wave
23	9	Sakuya Homing
24	10	Sakuya Angled
25	53	Sanae Snake
26	54	Sanae Frog
\.


--
-- Data for Name: difficulties; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.difficulties (difficulty_id, difficulty_name) FROM stdin;
1	Easy
2	Normal
3	Hard
4	Lunatic
5	Extra
\.


--
-- Data for Name: games; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.games (game_id, title, release_year) FROM stdin;
1	Touhou 6: Embodiment of Scarlet Devil	2002
2	Touhou 7: Perfect Cherry Blossom	2003
3	Touhou 8: Imperishable Night	2004
4	Touhou 9: Phantasmagoria of Flower View	2005
5	Touhou 10: Mountain of Faith	2007
6	Touhou 11: Subterranean Animism	2008
7	Touhou 12: Undefined Fantastic Object	2009
8	Touhou 13: Ten Desires	2011
9	Touhou 14: Double Dealing Character	2013
10	Touhou 15: Legacy of Lunatic Kingdom	2015
11	Touhou 16: Hidden Star in Four Seasons	2017
12	Touhou 17: Wily Beast and Weakest Creature	2019
13	Touhou 18: Unconnected Marketeers	2021
14	Touhou 20: Fosillized Wonders	2025
\.


--
-- Data for Name: players; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.players (player_id, nickname, region_id) FROM stdin;
115	ior	1
116	Feli	1
117	morth	1
118	おいたん	1
119	にゃんこ	1
120	Altair357	1
121	Apo	1
122	ZJM	1
123	idtn	1
124	STT	1
127	Origiri	1
129	IwanaM	1
130	shin	1
131	Lorenzo	2
132	ニャムニャム	1
141	mazakura	1
143	Nyilisa	1
144	Kero	1
146	Marisa	1
147	Borealis	1
148	幽々公	1
154	kisara	1
155	ゆっこ	1
156	Oscar	2
248	みんと缶	1
263	smilekj	1
266	Aeteas	1
267	Seiko	1
268	Haki	1
42	int	1
43	kana0603	1
44	いずみこ	1
45	ごぼう	1
46	MATSU	1
47	chum	2
48	Cactu	2
49	TrickOfHat	2
65	HS参謀	1
66	sp0	2
67	ゆーすけ	1
68	いな	1
69	clo-naga	1
70	Lcy	1
71	coco	1
73	YASU	1
74	緑茶瑠璃	1
75	LET	1
76	Alan	1
77	ASL	1
78	Leva	1
79	FRED	1
80	夏妃火火	1
81	Seppo Hovi	1
82	Nal Yoo	1
83	NALIS	1
84	R24	1
85	AM	1
86	水井むじん	1
87	PALM	1
88	Sakurei	2
89	Rurorulu	1
90	ななまる	1
91	Keroko	1
92	K・G	1
93	SOC	1
94	Z.Blade	1
95	coa	1
96	S.K	1
97	ZWB	1
98	LYX	1
99	denebw	1
100	dxk	1
101	キャル	1
102	seventh	1
103	EBM	1
222	YDH	1
223	Raymario Pokénic	2
225	MTR	2
226	あいたん	1
227	桜咲	1
228	ひみ☆	1
229	kkkn	1
230	どうぐ	1
231	うどんげん	1
232	Lutino	1
233	ざにっく	1
234	どぐう	1
337	CCO	1
241	ひろ♪☆	1
242	くどう	1
243	うどんしゅん	1
341	Serus	1
342	serenity	1
343	senki264	1
344	norm	1
345	KirbyComment	1
347	Raymarim Pokémonic	1
348	lmyk	1
350	itrln	1
351	幽谷響子	1
352	Aきあ	1
353	smilekij	1
354	Viddy	1
251	Balisman	2
252	Sottobil Tipsy	2
137	RB	2
\.


--
-- Data for Name: rankings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.rankings (ranking_id, player_id, global_rank, last_update) FROM stdin;
\.


--
-- Data for Name: records; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.records (record_id, player_id, game_id, character_id, difficulty_id, score, date) FROM stdin;

12	42	1	1	1	151209550	2023-11-18
13	42	1	2	1	174733570	2024-06-15
14	46	1	3	1	152283550	2010-10-16
15	46	1	4	1	156937990	2010-09-01
17	42	1	1	2	312301490	2023-07-02
18	42	1	2	2	366299400	2021-10-27
19	43	1	3	2	315314580	2023-03-12
20	43	1	4	2	320191010	2025-02-26
22	43	1	1	3	409240370	2025-01-22
23	44	1	2	3	551876370	2017-03-04
24	43	1	3	3	430720540	2025-02-25
25	43	1	4	3	441425110	2025-01-25
27	44	1	1	4	602275110	2018-03-31
28	45	1	2	4	804515970	2023-08-24
29	43	1	3	4	592945820	2023-01-01
30	45	1	4	4	652539520	2025-04-27
32	44	1	1	5	649850640	2025-09-16
33	44	1	2	5	678104400	2018-06-14
34	43	1	3	5	645089160	2018-06-10
35	44	1	4	5	676158100	2018-06-14
38	65	2	5	1	1799871950	2011-11-03
39	65	2	5	2	2001369010	2011-05-13
40	65	2	5	3	2548721870	2011-12-02
41	66	2	5	4	3207256600	2024-06-01
42	68	2	5	5	1400641310	2017-09-10
43	67	2	6	1	2042271460	2016-01-25
44	69	2	6	2	2167768950	2014-01-13
45	65	2	6	3	2854468430	2011-10-23
46	66	2	6	4	3643993290	2015-12-31
47	68	2	6	5	1509003300	2017-02-06
48	70	2	7	1	1950541980	2014-12-13
49	65	2	7	2	2132017710	2012-06-09
50	71	2	7	3	2576184230	2012-05-18
51	67	2	7	4	3233977750	2019-04-23
52	68	2	7	5	1306020210	2008-03-18
53	65	2	8	1	1768291980	2011-10-16
54	65	2	8	2	2011470500	2011-05-20
55	65	2	8	3	2387521220	2011-08-28
56	67	2	8	4	3095527470	2018-07-21
57	68	2	8	5	1244834970	2012-10-20
58	65	2	9	1	1777849120	2011-11-06
59	65	2	9	2	2014928800	2011-05-18
60	65	2	9	3	2379101080	2012-01-17
61	67	2	9	4	3257721510	2012-05-17
62	68	2	9	5	1277681830	2016-10-22
63	65	2	10	1	1929606150	2011-11-07
64	65	2	10	2	2104019640	2012-01-09
65	66	2	10	3	2795249510	2013-04-05
66	66	2	10	4	4026942260	2020-03-21
67	68	2	10	5	1412780710	2016-06-18
68	71	3	11	1	2637629490	2012-04-22
69	71	3	11	2	3893075004	2012-04-19
70	73	3	11	3	4507716810	2010-11-14
71	74	3	11	4	6137057201	2021-04-08
72	73	3	11	5	2957550150	2011-11-25
73	75	3	12	1	3084533670	2014-12-15
74	75	3	12	2	3895532070	2008-12-28
75	73	3	12	3	4737213890	2010-11-20
76	76	3	12	4	6168365790	2016-06-09
77	77	3	12	5	3021639920	2009-06-14
78	75	3	13	1	3012091640	2014-06-04
79	75	3	13	2	4007899720	2009-11-19
80	73	3	13	3	4790041420	2009-12-23
81	78	3	13	4	6755587090	2025-07-13
82	77	3	13	5	3000284220	2012-03-13
83	71	3	14	1	2764571140	2015-02-24
84	75	3	14	2	3907285270	2009-06-25
85	73	3	14	3	4740759550	2012-10-13
86	78	3	14	4	6711233720	2023-02-02
87	78	3	14	5	3024418500	2023-03-28
88	80	3	15	1	2718513210	2018-04-22
89	79	3	15	2	3670515640	2010-01-15
90	73	3	15	3	3933954880	2008-12-14
91	73	3	15	4	4952610380	2010-04-30
92	75	3	15	5	2501958550	2005-06-07
93	81	3	16	1	1783066590	2009-09-27
94	82	3	16	2	2495641950	2010-04-10
95	73	3	16	3	3282506140	2009-10-30
96	73	3	16	4	3973007340	2009-06-06
97	73	3	16	5	2112244750	2009-11-11
98	71	3	17	1	3127823070	2015-01-10
99	83	3	17	2	3966520420	2015-10-17
100	73	3	17	3	4453549000	2009-12-26
101	73	3	17	4	5527494830	2021-06-12
102	75	3	17	5	2639609000	2001-05-02
103	82	3	18	1	1893206400	2008-12-16
104	82	3	18	2	2485193170	2014-11-21
105	73	3	18	3	3147925420	2012-10-13
106	84	3	18	4	3949470990	2025-01-10
107	84	3	18	5	2092076100	2025-07-25
108	85	3	19	1	2677708820	2008-06-06
109	79	3	19	2	3437783700	2009-10-07
110	73	3	19	3	3916398860	2011-12-24
111	73	3	19	4	4780031130	2013-04-13
112	71	3	19	5	2525295090	2010-04-01
113	86	3	20	1	2024924590	2009-07-26
114	83	3	20	2	2755844610	2008-05-26
115	86	3	20	3	3371851480	2018-02-11
116	83	3	20	4	4209123500	2009-06-15
117	77	3	20	5	2221694900	2011-08-08
118	71	3	21	1	3379425090	2015-04-13
119	83	3	21	2	4496668100	2015-09-15
120	87	3	21	3	5242686800	2015-04-29
121	78	3	21	4	7017785890	2023-07-04
122	88	3	21	5	3178460830	2023-07-23
123	86	3	22	1	1778146800	2008-12-17
124	73	3	22	2	2485302400	2008-05-28
125	73	3	22	3	3143557450	2010-12-23
126	74	3	22	4	4078342600	2009-06-15
127	73	3	22	5	2101505900	2007-04-18
164	89	4	23	1	184965500	2022-11-18
165	89	4	23	2	299910030	2024-11-05
166	89	4	23	3	314236850	2022-11-19
167	89	4	23	4	398699280	2025-02-01
168	89	4	23	5	212897200	2023-07-01
169	89	4	24	1	264765150	2023-04-02
170	89	4	24	2	559399300	2022-10-12
171	89	4	24	3	589742710	2024-08-02
172	89	4	24	4	620184190	2024-08-04
173	89	4	24	5	303274100	2023-09-21
174	89	4	25	1	187369540	2021-03-15
175	89	4	25	2	267725980	2022-07-30
176	89	4	25	3	271408750	2022-07-30
177	89	4	25	4	305459660	2023-05-19
178	89	4	25	5	198936460	2023-07-01
179	89	4	26	1	214582140	2023-02-05
180	89	4	26	2	324728890	2023-08-09
181	89	4	26	3	365400960	2023-08-09
182	89	4	26	4	403804530	2023-09-10
183	89	4	26	5	257128470	2024-03-02
184	89	4	27	1	232765110	2022-09-14
185	89	4	27	2	338202330	2022-09-14
186	89	4	27	3	346819580	2022-09-14
187	89	4	27	4	377211380	2023-01-18
188	89	4	27	5	209267440	2022-09-14
189	89	4	28	1	165498320	2023-02-14
190	89	4	28	2	260879360	2023-04-30
191	89	4	28	3	264391580	2023-04-30
192	89	4	28	4	290912660	2023-06-03
193	89	4	28	5	168335270	2023-07-07
194	89	4	29	1	206800970	2023-03-07
195	89	4	29	2	301565660	2023-07-04
196	89	4	29	3	308253960	2023-07-04
197	89	4	29	4	326352570	2023-09-02
198	89	4	29	5	202783850	2023-09-02
199	89	4	30	1	208158540	2025-05-30
200	89	4	30	2	532554420	2025-03-20
201	89	4	30	3	500176210	2025-03-19
202	89	4	30	4	448864290	2025-05-05
203	89	4	30	5	189028350	2024-08-31
204	89	4	31	1	187279080	2023-01-02
205	89	4	31	2	266690050	2022-08-03
206	89	4	31	3	281429860	2022-11-06
207	89	4	31	4	301196960	2022-02-24
208	89	4	31	5	206138330	2023-01-26
209	89	4	32	1	116572760	2025-07-11
210	89	4	32	2	175388290	2022-10-13
211	89	4	32	3	172000050	2020-09-21
212	89	4	32	4	203694960	2022-05-24
213	89	4	32	5	212021670	2020-09-01
214	89	4	33	1	153668840	2021-12-24
215	89	4	33	2	168927780	2022-04-16
216	89	4	33	3	191127130	2025-09-21
217	89	4	33	4	208970520	2025-06-29
218	89	4	33	5	244339510	2025-07-19
219	89	4	34	1	187543070	2021-12-26
220	89	4	34	2	321548740	2025-03-24
221	89	4	34	3	344145000	2025-02-22
222	89	4	34	4	462287690	2015-12-12
223	89	4	34	5	230599850	2025-05-11
224	89	4	35	1	191137010	2023-01-01
225	89	4	35	2	464438720	2025-04-24
226	89	4	35	3	480109410	2025-03-17
227	89	4	35	4	560150800	2023-07-26
228	89	4	35	5	204757240	2025-05-19
229	89	4	36	1	277702560	2022-11-05
230	89	4	36	2	1025484800	2024-12-19
231	89	4	36	3	1128545800	2025-05-11
232	89	4	36	4	1220451870	2023-04-29
233	89	4	36	5	347191350	2025-05-23
234	90	5	37	1	1551990910	2012-01-04
235	91	5	37	2	1698758210	2012-04-11
236	92	5	37	3	2013453210	2024-10-05
237	93	5	37	4	2171749120	2025-06-29
238	90	5	37	5	987343680	2012-05-21
239	94	5	38	1	1561807140	2011-05-11
240	90	5	38	2	1692041350	2011-01-11
241	90	5	38	3	2043365070	2025-04-16
242	93	5	38	4	2200625580	2025-07-15
243	102	5	38	5	995609930	2012-07-23
244	95	5	39	1	1562041780	2011-06-19
245	96	5	39	2	1650463860	2023-03-22
246	90	5	39	3	2015786990	2025-03-22
247	93	5	39	4	2181997680	2025-03-22
248	102	5	39	5	993681350	2018-04-29
249	90	5	40	1	1557274280	2012-02-16
250	97	5	40	2	1682878740	2011-11-01
251	98	5	40	3	2027974800	2024-08-02
252	99	5	40	4	2186757130	2025-01-20
253	102	5	40	5	990867060	2017-08-13
254	98	5	41	1	1590048550	2012-06-13
255	90	5	41	2	1718140240	2012-04-21
256	96	5	41	3	2040858080	2025-02-17
257	100	5	41	4	2207363460	2025-09-12
258	90	5	41	5	988226530	2012-08-12
259	101	5	42	1	1590987270	2024-12-31
260	101	5	42	2	1700788380	2025-04-30
261	98	5	42	3	2067687430	2024-03-30
262	103	5	42	4	2221100590	2024-09-09
263	90	5	42	5	1003229380	2016-06-28
264	115	6	43	1	695043750	2021-01-18
265	116	6	43	2	1171182300	2024-03-04
266	117	6	43	3	1998503870	2023-03-04
267	115	6	43	4	5343652940	2023-08-30
268	118	6	43	5	1135696210	2025-03-08
269	115	6	44	1	668821050	2021-02-02
270	119	6	44	2	1029682710	2024-12-14
271	127	6	44	3	1733188660	2019-01-09
272	115	6	44	4	4001598250	2019-10-09
273	116	6	44	5	1121814290	2025-07-17
274	115	6	45	1	702282900	2021-02-09
275	119	6	45	2	1071892480	2024-12-01
276	120	6	45	3	1676141540	2019-02-09
277	115	6	45	4	4146651230	2020-10-21
278	121	6	45	5	1093743800	2025-07-19
279	115	6	46	1	771041960	2021-02-17
280	122	6	46	2	1228844210	2023-06-29
281	115	6	46	3	2168402810	2022-07-11
282	115	6	46	4	4820841860	2024-08-20
283	123	6	46	5	1133521770	2025-03-28
284	115	6	47	1	754638000	2021-03-07
285	124	6	47	2	1237253700	2023-09-26
286	119	6	47	3	2100324900	2024-12-11
287	115	6	47	4	4721299000	2025-05-24
288	116	6	47	5	1108671250	2025-06-30
289	119	6	48	1	694935260	2023-02-28
290	119	6	48	2	975303230	2023-06-05
291	92	6	48	3	1401024260	2015-02-11
292	122	6	48	4	3601041810	2021-05-20
293	77	6	48	5	1081890510	2025-03-26
445	222	11	69	1	1281637700	2025-07-25
446	223	11	69	2	3058368650	2021-05-11
447	223	11	69	3	3927962050	2021-05-20
448	156	11	69	4	5314828090	2021-05-20
449	225	11	70	1	1766782590	2021-01-30
450	226	11	70	2	3040390490	2023-09-20
451	227	11	70	3	3243585400	2023-06-10
452	226	11	70	4	4341516200	2023-07-05
453	123	11	114	5	3507478380	2024-06-21
454	225	11	71	1	1403799180	2019-11-28
455	228	11	71	2	5351980400	2024-01-07
456	228	11	71	3	6668797200	2023-06-10
457	226	11	71	4	8474682890	2024-07-05
458	234	11	72	1	1912673640	2022-11-06
459	234	11	72	2	3903467190	2022-12-04
460	234	11	72	3	3746171320	2024-11-09
461	229	11	72	4	6044739440	2024-12-06
462	234	11	81	1	1345180560	2025-03-03
463	223	11	81	2	3361733300	2021-05-12
464	223	11	81	3	4072763300	2021-05-20
465	234	11	81	4	5470222800	2025-07-20
466	225	11	82	1	1745279550	2021-03-15
467	226	11	82	2	3190555050	2021-09-29
468	226	11	82	3	3593586500	2022-04-09
469	226	11	82	4	4519218450	2025-07-10
470	123	11	115	5	3518641940	2024-07-01
471	222	11	77	1	1543708530	2025-07-22
472	223	11	77	2	3472738100	2021-04-28
473	223	11	77	3	4242401600	2021-06-09
474	232	11	77	4	5943818370	2024-08-15
475	225	11	78	1	1906732230	2021-08-21
476	226	11	78	2	3061507370	2021-09-15
477	226	11	78	3	3680071410	2023-10-13
478	226	11	78	4	4283223840	2024-10-13
479	123	11	116	5	3549454900	2024-07-16
480	225	11	79	1	2120131470	2023-01-02
481	228	11	79	2	5607183880	2023-12-26
482	233	11	79	3	7858005900	2023-12-17
483	233	11	79	4	9985537830	2024-07-16
484	234	11	80	1	2056648190	2024-11-03
485	226	11	80	2	4032201380	2023-12-19
486	234	11	80	3	3970311840	2023-08-08
487	234	11	80	4	6185966920	2024-05-19
488	223	11	73	1	1320790900	2021-07-30
489	223	11	73	2	3055181100	2021-05-10
490	234	11	73	3	3909421400	2024-03-01
491	234	11	73	4	4928814300	2024-03-01
492	225	11	74	1	1811703060	2021-12-19
493	226	11	74	2	3109503800	2021-05-15
494	226	11	74	3	3824051010	2024-01-15
495	226	11	74	4	4440941850	2024-05-15
496	123	11	117	5	3519680900	2024-07-11
497	225	11	75	1	1648625290	2021-05-20
498	228	11	75	2	5447151380	2021-05-20
499	228	11	75	3	7114586980	2021-08-29
500	228	11	75	4	9020416760	2021-08-29
501	234	11	76	1	1943365750	2024-11-03
502	226	11	76	2	3911614610	2023-12-17
308	92	7	49	1	1956472420	2022-11-26
503	234	11	76	3	3767902010	2022-10-26
504	234	11	76	4	6064700770	2024-12-01
595	252	12	89	4	9999999990	2024-05-08
596	147	12	89	5	2774430020	2024-09-23
597	248	12	90	1	3591762000	2023-01-05
598	248	12	90	2	5435684200	2023-01-08
599	248	12	90	3	6577038880	2023-01-08
600	248	12	90	4	8203761040	2023-02-14
601	147	12	90	5	1715772140	2024-03-26
602	248	12	91	1	3052652700	2022-08-26
603	248	12	91	2	5442200920	2024-09-01
604	248	12	91	3	6550462810	2022-11-08
322	92	7	49	2	2616139560	2023-02-18
323	92	7	49	3	2899478220	2019-06-02
324	92	7	49	4	3103142260	2022-06-22
325	129	7	49	5	671921550	2022-01-25
326	92	7	50	1	1990147610	2024-04-07
327	92	7	50	2	2618098310	2023-09-22
328	130	7	50	3	3045746740	2013-06-16
329	131	7	50	4	3005784490	2021-12-26
330	129	7	50	5	637570100	2025-01-05
331	92	7	51	1	2164290730	2019-01-26
332	92	7	51	2	2883041990	2018-11-10
333	92	7	51	3	3384882390	2020-06-08
336	137	7	51	4	3651012750	2024-03-05
337	129	7	51	5	720371100	2022-12-26
338	92	7	52	1	2168138790	2024-11-03
339	92	7	52	2	2904009330	2024-12-01
340	92	7	52	3	3217787500	2020-05-08
341	92	7	52	4	3341163080	2022-05-29
342	132	7	52	5	707175050	2025-06-25
343	92	7	53	1	2114171760	2024-03-16
344	92	7	53	2	2813570340	2019-05-06
345	92	7	53	3	3075658640	2021-06-13
346	123	7	53	4	3250403790	2021-05-13
347	129	7	53	5	654737910	2022-05-25
348	92	7	54	1	2199534280	2025-09-09
349	92	7	54	2	3037877800	2024-11-16
350	92	7	54	3	3300588460	2024-01-01
351	92	7	54	4	3616918520	2021-06-07
352	132	7	54	5	776144040	2022-04-04
353	92	9	59	1	927161540	2022-12-24
354	141	9	59	2	1129691830	2023-06-26
355	141	9	59	3	1323422250	2023-06-21
356	137	9	59	4	1722978370	2023-06-17
357	143	9	59	5	823169540	2024-08-14
358	92	9	60	1	779435930	2021-06-10
359	92	9	60	2	914525760	2017-08-08
360	92	9	60	3	1021298790	2018-11-02
361	92	9	60	4	1269523460	2025-07-13
362	117	9	60	5	752768230	2022-04-13
363	144	9	61	1	902513550	2025-07-05
364	141	9	61	2	1024059800	2025-03-27
365	144	9	61	3	1300489740	2025-06-18
366	144	9	61	4	1519065160	2025-06-01
367	117	9	61	5	759382180	2022-05-15
368	144	9	62	1	886986030	2025-02-27
369	144	9	62	2	1186096150	2025-04-12
370	144	9	62	3	1500192040	2025-01-28
371	144	9	62	4	2021328910	2024-12-08
372	146	9	62	5	1260747270	2025-05-15
373	147	9	63	1	940150970	2022-06-11
374	141	9	63	2	1096201790	2023-06-20
375	141	9	63	3	1330572640	2023-06-27
376	141	9	63	4	1707422900	2025-06-27
377	117	9	63	5	792750400	2024-01-25
378	98	9	64	1	1118074340	2014-10-24
379	148	9	64	2	1704616870	2025-02-26
380	92	9	64	3	1932054640	2025-12-31
381	103	9	64	4	2496848010	2025-05-18
382	117	9	64	5	876669670	2024-04-22
383	92	10	65	1	1261578740	2021-01-10
384	92	10	65	2	1831321050	2023-03-21
385	92	10	65	3	1919475990	2024-10-19
386	137	10	65	4	3022509750	2025-07-16
387	123	10	65	5	963262690	2023-03-31
388	92	10	66	1	1342892730	2022-04-29
389	92	10	66	2	1946262650	2022-09-10
390	155	10	66	3	2498678950	2025-03-12
391	155	10	66	4	3021851070	2025-06-21
392	154	10	66	5	923555520	2016-05-12
393	92	10	67	1	1639944540	2021-01-17
394	154	10	67	2	2625622880	2017-09-18
395	154	10	67	3	2711256800	2018-01-08
396	137	10	67	4	3410044890	2025-07-19
397	154	10	67	5	1009636890	2017-03-14
398	137	10	68	1	1877770150	2022-11-11
399	137	10	68	2	3038789390	2021-11-13
400	137	10	68	3	3206264130	2016-12-16
401	156	10	68	4	3864946440	2025-07-15
402	156	10	68	5	1073686620	2025-08-14
524	222	11	83	1	1551613900	2025-07-07
525	241	11	83	2	5237512740	2024-04-06
526	241	11	83	3	6107251150	2023-06-10
527	241	11	83	4	8046964950	2021-07-03
528	242	11	84	1	2093838890	2022-11-05
529	243	11	84	2	4069582470	2023-08-10
530	242	11	84	3	4105592190	2022-07-03
531	229	11	84	4	6350255160	2022-07-12
572	248	12	85	1	3493459300	2023-02-16
573	248	12	85	2	5535777660	2024-01-13
574	248	12	85	3	6219838760	2023-10-13
575	92	12	85	4	8158880000	2024-03-03
576	147	12	85	5	1819343220	2024-03-07
577	248	12	86	1	4382652850	2023-10-06
578	248	12	86	2	7319600570	2022-10-18
579	248	12	86	3	9014027910	2022-10-13
580	248	12	86	4	9999999990	2023-10-22
581	147	12	86	5	2626874070	2024-03-14
582	248	12	87	1	3546849360	2023-02-07
583	248	12	87	2	5453636920	2024-01-05
584	248	12	87	3	6215961880	2022-09-20
585	248	12	87	4	8207593890	2023-06-21
586	147	12	87	5	1716115870	2024-03-08
587	248	12	88	1	3407339610	2023-05-01
588	248	12	88	2	5329523680	2024-01-15
589	248	12	88	3	6357921540	2023-11-05
590	248	12	88	4	8235973630	2023-11-13
591	147	12	88	5	1674917360	2024-02-25
592	248	12	89	1	4873546650	2022-11-14
593	248	12	89	2	7993478110	2022-11-17
594	248	12	89	3	9999999990	2022-12-06
605	248	12	91	4	8162971100	2023-12-25
606	147	12	91	5	1634081620	2024-02-27
607	248	12	92	1	4326093930	2023-08-23
608	248	12	92	2	7310420920	2023-08-21
609	248	12	92	3	9074879690	2023-11-30
610	248	12	92	4	9999999990	2024-07-30
611	251	12	92	5	2372788000	2024-09-03
612	248	12	93	1	3997115310	2022-08-26
613	248	12	93	2	5981651240	2024-01-12
614	248	12	93	3	7380611670	2023-11-20
615	248	12	93	4	9027051690	2023-11-17
616	147	12	93	5	1721961600	2024-03-01
622	119	13	94	1	1506260000	2025-02-19
623	119	13	94	2	4429979290	2025-04-04
624	123	13	94	3	6717042050	2025-02-15
625	123	13	94	4	9999999990	2025-11-04
626	119	13	94	5	3845087960	2025-06-28
627	119	13	95	1	1459050940	2025-02-20
628	263	13	95	2	4228847450	2023-11-07
629	123	13	95	3	6557472300	2025-02-17
630	123	13	95	4	9999999990	2025-11-11
631	119	13	95	5	3857820910	2025-06-17
632	119	13	113	1	1941556640	2025-03-11
633	71	13	113	2	6522829390	2021-06-05
634	71	13	113	3	9999999990	2021-05-31
635	137	13	113	4	9999999990	2023-08-14
636	123	13	113	5	8467415250	2025-07-01
637	119	13	96	1	1545895610	2025-02-22
638	266	13	96	2	4552150430	2022-05-04
639	267	13	96	3	6783514650	2022-09-30
640	268	13	96	4	9999999990	2023-04-08
641	123	13	96	5	3862839840	2023-04-09
714	337	14	97	1	10263676700	2025-09-16
715	337	14	97	2	11668114100	2025-09-21
716	337	14	97	3	10772206000	2025-09-14
717	92	14	97	4	14998915310	2025-09-10
718	43	14	97	5	2822445720	2025-09-11
719	337	14	98	1	9864614570	2025-09-15
720	337	14	98	2	12119862030	2025-09-11
721	92	14	98	3	11559518200	2025-09-15
722	92	14	98	4	14722531780	2025-09-11
723	341	14	98	5	2582966300	2025-09-23
724	337	14	99	1	10193539340	2025-09-30
725	337	14	99	2	12294700970	2025-09-29
726	92	14	99	3	13454697760	2025-09-15
727	92	14	99	4	14005964910	2025-09-09
728	341	14	99	5	2649796890	2025-09-22
729	337	14	100	1	10176317540	2025-09-27
730	337	14	100	2	11837564900	2025-09-27
731	92	14	100	3	13574766070	2025-09-15
732	92	14	100	4	14943858850	2025-09-09
733	341	14	100	5	2581125080	2025-09-22
734	146	14	101	1	9211757540	2025-08-29
735	146	14	101	2	10701277530	2025-09-22
736	337	14	101	3	9935204020	2025-09-12
737	344	14	101	4	12862823580	2025-09-23
738	342	14	101	5	1785253580	2025-08-22
739	337	14	102	1	9090142110	2025-09-16
740	337	14	102	2	10833341100	2025-09-19
741	337	14	102	3	10253199280	2025-09-12
742	92	14	102	4	12801249120	2025-09-12
743	343	14	102	5	1963940720	2025-09-08
744	337	14	103	1	11928661040	2025-10-07
745	337	14	103	2	12281306740	2025-09-29
746	92	14	103	3	14150872790	2025-09-14
747	344	14	103	4	17088109680	2025-10-06
748	352	14	103	5	3140799090	2025-09-09
749	337	14	104	1	9182772080	2025-09-30
750	345	14	104	2	9985665050	2025-08-22
751	92	14	104	3	8663476070	2025-09-07
752	92	14	104	4	6944847860	2025-09-07
753	353	14	104	5	467294090	2025-09-08
754	337	14	105	1	9797549740	2025-09-25
755	337	14	105	2	10512102710	2025-09-19
756	92	14	105	3	12041075630	2025-09-08
757	92	14	105	4	13857408090	2025-09-14
758	353	14	105	5	2395540370	2025-09-20
759	337	14	106	1	9310712940	2025-09-10
760	337	14	106	2	10626864080	2025-09-13
761	344	14	106	3	12653623820	2025-09-17
762	92	14	106	4	15012859430	2025-09-14
763	342	14	106	5	2769080260	2025-09-19
764	337	14	107	1	10476924030	2025-09-13
765	337	14	107	2	11425274760	2025-09-27
766	337	14	107	3	12828465750	2025-09-15
767	344	14	107	4	14587363640	2025-09-28
768	341	14	107	5	2732440140	2025-09-15
769	337	14	108	1	9718137460	2025-09-21
770	337	14	108	2	11227775480	2025-09-23
771	344	14	108	3	12684866370	2025-09-17
772	92	14	108	4	14844153600	2025-09-25
773	341	14	108	5	2647757290	2025-09-22
774	337	14	109	1	9787625910	2025-09-26
775	344	14	109	2	11072363380	2025-09-22
776	344	14	109	3	12743655470	2025-09-17
777	344	14	109	4	14599801400	2025-09-30
778	353	14	109	5	2807730120	2025-09-19
779	337	14	110	1	10281712940	2025-09-30
780	337	14	110	2	11274356370	2025-09-22
781	92	14	110	3	12928496510	2025-09-14
782	92	14	110	4	15177201300	2025-09-21
783	342	14	110	5	2842555170	2025-09-19
784	337	14	111	1	10497989420	2025-09-21
785	337	14	111	2	11584996340	2025-09-23
786	344	14	111	3	13177650300	2025-09-17
787	92	14	111	4	15449850670	2025-09-19
788	341	14	111	5	3018965130	2025-09-16
789	337	14	112	1	9966412070	2025-09-27
790	337	14	112	2	10887901680	2025-09-27
791	344	14	112	3	12275903900	2025-09-17
792	92	14	112	4	14588570850	2025-09-24
793	352	14	112	5	2985594050	2025-09-15
\.


--
-- Data for Name: regions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.regions (region_id, region_name) FROM stdin;
1	East (Japan)
2	West (Other World)
\.


--
-- Data for Name: stage_runs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.stage_runs (record_id, stage_id, stage_score) FROM stdin;
12	1	7176310
12	2	25666070
12	3	60346980
12	4	105700900
12	5	151209550
17	1	10565190
17	2	31179790
17	3	84271520
17	4	151524320
17	5	225206910
17	6	312301490
\.


--
-- Data for Name: stages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.stages (stage_id, game_id, stage_number, stage_name) FROM stdin;
1	1	1	Stage 1
2	1	2	Stage 2
3	1	3	Stage 3
4	1	4	Stage 4
5	1	5	Stage 5
6	1	6	Stage 6
7	1	7	Extra
8	2	1	Stage 1
9	2	2	Stage 2
10	2	3	Stage 3
11	2	4	Stage 4
12	2	5	Stage 5
13	2	6	Stage 6
14	2	7	Extra
15	3	1	Stage 1
16	3	2	Stage 2
17	3	3	Stage 3
18	3	4	Stage 4
19	3	5	Stage 5
20	3	6	Stage 6
21	3	7	Extra
22	5	1	Stage 1
23	5	2	Stage 2
24	5	3	Stage 3
25	5	4	Stage 4
26	5	5	Stage 5
27	5	6	Stage 6
28	5	7	Extra
29	6	1	Stage 1
30	6	2	Stage 2
31	6	3	Stage 3
32	6	4	Stage 4
33	6	5	Stage 5
34	6	6	Stage 6
35	6	7	Extra
36	7	1	Stage 1
37	7	2	Stage 2
38	7	3	Stage 3
39	7	4	Stage 4
40	7	5	Stage 5
41	7	6	Stage 6
42	7	7	Extra
43	8	1	Stage 1
44	8	2	Stage 2
45	8	3	Stage 3
46	8	4	Stage 4
47	8	5	Stage 5
48	8	6	Stage 6
49	8	7	Extra
50	9	1	Stage 1
51	9	2	Stage 2
52	9	3	Stage 3
53	9	4	Stage 4
54	9	5	Stage 5
55	9	6	Stage 6
56	9	7	Extra
57	10	1	Stage 1
58	10	2	Stage 2
59	10	3	Stage 3
60	10	4	Stage 4
61	10	5	Stage 5
62	10	6	Stage 6
63	10	7	Extra
64	11	1	Stage 1
65	11	2	Stage 2
66	11	3	Stage 3
67	11	4	Stage 4
68	11	5	Stage 5
69	11	6	Stage 6
70	11	7	Extra
71	12	1	Stage 1
72	12	2	Stage 2
73	12	3	Stage 3
74	12	4	Stage 4
75	12	5	Stage 5
76	12	6	Stage 6
77	12	7	Extra
78	13	1	Stage 1
79	13	2	Stage 2
80	13	3	Stage 3
81	13	4	Stage 4
82	13	5	Stage 5
83	13	6	Stage 6
84	13	7	Extra
85	14	1	Stage 1
86	14	2	Stage 2
87	14	3	Stage 3
88	14	4	Stage 4
89	14	5	Stage 5
90	14	6	Stage 6
91	14	7	Extra
92	4	1	Stage 1
93	4	2	Stage 2
94	4	3	Stage 3
95	4	4	Stage 4
96	4	5	Stage 5
97	4	6	Stage 6
98	4	7	Stage 7
99	4	8	Stage 8
100	4	9	Stage 9
101	4	10	Extra
\.


--
-- Name: characters_character_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.characters_character_id_seq', 117, true);


--
-- Name: countries_country_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.countries_country_id_seq', 1, false);


--
-- Name: difficulties_difficulty_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.difficulties_difficulty_id_seq', 5, true);


--
-- Name: games_game_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.games_game_id_seq', 22, true);


--
-- Name: players_player_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.players_player_id_seq', 354, true);


--
-- Name: rankings_ranking_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.rankings_ranking_id_seq', 1, false);


--
-- Name: records_record_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.records_record_id_seq', 1, false);


--
-- Name: shottype_aliases_alias_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.shottype_aliases_alias_id_seq', 27, true);


--
-- Name: stages_stage_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.stages_stage_id_seq', 101, true);


--
-- Name: characters characters_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.characters
    ADD CONSTRAINT characters_pkey PRIMARY KEY (character_id);


--
-- Name: regions countries_country_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.regions
    ADD CONSTRAINT countries_country_name_key UNIQUE (region_name);


--
-- Name: regions countries_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.regions
    ADD CONSTRAINT countries_pkey PRIMARY KEY (region_id);


--
-- Name: difficulties difficulties_difficulty_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.difficulties
    ADD CONSTRAINT difficulties_difficulty_name_key UNIQUE (difficulty_name);


--
-- Name: difficulties difficulties_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.difficulties
    ADD CONSTRAINT difficulties_pkey PRIMARY KEY (difficulty_id);


--
-- Name: games games_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.games
    ADD CONSTRAINT games_pkey PRIMARY KEY (game_id);


--
-- Name: players players_nickname_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.players
    ADD CONSTRAINT players_nickname_key UNIQUE (nickname);


--
-- Name: players players_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.players
    ADD CONSTRAINT players_pkey PRIMARY KEY (player_id);


--
-- Name: rankings rankings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rankings
    ADD CONSTRAINT rankings_pkey PRIMARY KEY (ranking_id);


--
-- Name: records records_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.records
    ADD CONSTRAINT records_pkey PRIMARY KEY (record_id);


--
-- Name: characters_alt shottype_aliases_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.characters_alt
    ADD CONSTRAINT shottype_aliases_pkey PRIMARY KEY (alias_id);


--
-- Name: stages stages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stages
    ADD CONSTRAINT stages_pkey PRIMARY KEY (stage_id);


--
-- Name: records update_rank_delete; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_rank_delete AFTER DELETE ON public.records FOR EACH ROW EXECUTE FUNCTION public.update_rankings();


--
-- Name: records update_rank_insert; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_rank_insert AFTER INSERT ON public.records FOR EACH ROW EXECUTE FUNCTION public.update_rankings();


--
-- Name: records update_rank_update; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_rank_update AFTER UPDATE ON public.records FOR EACH ROW EXECUTE FUNCTION public.update_rankings();


--
-- Name: characters characters_game_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.characters
    ADD CONSTRAINT characters_game_id_fkey FOREIGN KEY (game_id) REFERENCES public.games(game_id) ON DELETE CASCADE;


--
-- Name: players fk_region; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.players
    ADD CONSTRAINT fk_region FOREIGN KEY (region_id) REFERENCES public.regions(region_id);


--
-- Name: rankings rankings_player_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rankings
    ADD CONSTRAINT rankings_player_id_fkey FOREIGN KEY (player_id) REFERENCES public.players(player_id) ON DELETE CASCADE;


--
-- Name: records records_character_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.records
    ADD CONSTRAINT records_character_id_fkey FOREIGN KEY (character_id) REFERENCES public.characters(character_id) ON DELETE CASCADE;


--
-- Name: records records_difficulty_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.records
    ADD CONSTRAINT records_difficulty_id_fkey FOREIGN KEY (difficulty_id) REFERENCES public.difficulties(difficulty_id) ON DELETE CASCADE;


--
-- Name: records records_game_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.records
    ADD CONSTRAINT records_game_id_fkey FOREIGN KEY (game_id) REFERENCES public.games(game_id) ON DELETE CASCADE;


--
-- Name: records records_player_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.records
    ADD CONSTRAINT records_player_id_fkey FOREIGN KEY (player_id) REFERENCES public.players(player_id) ON DELETE CASCADE;


--
-- Name: characters_alt shottype_aliases_character_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.characters_alt
    ADD CONSTRAINT shottype_aliases_character_id_fkey FOREIGN KEY (character_id) REFERENCES public.characters(character_id) ON DELETE CASCADE;


--
-- Name: stage_runs stage_runs_record_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stage_runs
    ADD CONSTRAINT stage_runs_record_id_fkey FOREIGN KEY (record_id) REFERENCES public.records(record_id) ON DELETE CASCADE;


--
-- Name: stage_runs stage_runs_stage_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stage_runs
    ADD CONSTRAINT stage_runs_stage_id_fkey FOREIGN KEY (stage_id) REFERENCES public.stages(stage_id) ON DELETE CASCADE;


--
-- Name: stages stages_game_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stages
    ADD CONSTRAINT stages_game_id_fkey FOREIGN KEY (game_id) REFERENCES public.games(game_id) ON DELETE CASCADE;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT USAGE ON SCHEMA public TO viewer;
GRANT USAGE ON SCHEMA public TO moderator;


--
-- Name: TABLE characters; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.characters TO viewer;
GRANT ALL ON TABLE public.characters TO moderator;


--
-- Name: TABLE characters_alt; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.characters_alt TO viewer;
GRANT ALL ON TABLE public.characters_alt TO moderator;


--
-- Name: TABLE character_names; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.character_names TO viewer;
GRANT ALL ON TABLE public.character_names TO moderator;


--
-- Name: SEQUENCE characters_character_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.characters_character_id_seq TO moderator;


--
-- Name: TABLE regions; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.regions TO viewer;
GRANT ALL ON TABLE public.regions TO moderator;


--
-- Name: SEQUENCE countries_country_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.countries_country_id_seq TO moderator;


--
-- Name: TABLE difficulties; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.difficulties TO viewer;
GRANT ALL ON TABLE public.difficulties TO moderator;


--
-- Name: SEQUENCE difficulties_difficulty_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.difficulties_difficulty_id_seq TO moderator;


--
-- Name: TABLE games; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.games TO viewer;
GRANT ALL ON TABLE public.games TO moderator;


--
-- Name: SEQUENCE games_game_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.games_game_id_seq TO moderator;


--
-- Name: TABLE players; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.players TO viewer;
GRANT ALL ON TABLE public.players TO moderator;


--
-- Name: TABLE records; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.records TO viewer;
GRANT ALL ON TABLE public.records TO moderator;


--
-- Name: TABLE max_records; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.max_records TO viewer;
GRANT ALL ON TABLE public.max_records TO moderator;


--
-- Name: SEQUENCE players_player_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.players_player_id_seq TO moderator;


--
-- Name: TABLE rankings; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.rankings TO viewer;
GRANT ALL ON TABLE public.rankings TO moderator;


--
-- Name: SEQUENCE rankings_ranking_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.rankings_ranking_id_seq TO moderator;


--
-- Name: SEQUENCE records_record_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.records_record_id_seq TO moderator;


--
-- Name: SEQUENCE shottype_aliases_alias_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.shottype_aliases_alias_id_seq TO moderator;


--
-- Name: TABLE stage_runs; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.stage_runs TO viewer;
GRANT ALL ON TABLE public.stage_runs TO moderator;


--
-- Name: TABLE stages; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.stages TO viewer;
GRANT ALL ON TABLE public.stages TO moderator;


--
-- Name: SEQUENCE stages_stage_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.stages_stage_id_seq TO moderator;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO moderator;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT ON TABLES TO viewer;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO moderator;


--
-- PostgreSQL database dump complete
--

\unrestrict XyxZlphAaME8FjMhQnbq7ep5FTfG6e1c3tnoiha2ICSQWtj2LRYZZzxMR3FOrMf

