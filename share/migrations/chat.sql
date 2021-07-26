-- 1 up

create table if not exists chat
(
    chat_pkey serial not null,
    editnum bigint NOT NULL DEFAULT 1,
    insby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'System',
    insdatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    modby character varying(25) COLLATE pg_catalog."default" NOT NULL DEFAULT 'System',
    moddatetime timestamp without time zone NOT NULL DEFAULT NOW(),
    userid varchar NOT NULL,
    company varchar NOT NULL,
    username varchar NOT NULL,
    message varchar NOT NULL,
    CONSTRAINT chat_pkey PRIMARY KEY (chat_pkey)
);

CREATE INDEX IDX_insdatetime_userid
    ON chat(insdatetime, userid);

CREATE INDEX IDX_insdatetime_userid_company
    ON chat(insdatetime, userid, company);

-- 1 down