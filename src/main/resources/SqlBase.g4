/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

grammar SqlBase;

singleStatement
    : statement EOF
    ;

statement
    : CREATE TIMESERIES timeseriesPath WITH attributeClauses #createTimeseries
    | DELETE TIMESERIES prefixPath (COMMA prefixPath)* #deleteTimeseries
    | INSERT INTO timeseriesPath insertColumnSpec VALUES insertValuesSpec #insertStatement
    | UPDATE prefixPath setClause whereClause? #updateStatement // not suppert yet
    | DELETE FROM prefixPath (COMMA prefixPath)* (whereClause)? #deleteStatement
    | SET STORAGE GROUP TO prefixPath #setStorageGroup
    | DELETE STORAGE GROUP prefixPath (COMMA prefixPath)* #deleteStorageGroup
    | CREATE PROPERTY ID #createProperty
    | ADD LABEL label=ID TO PROPERTY propertyName=ID #addLabel
    | DELETE LABEL label=ID FROM PROPERTY propertyName=ID #deleteLabel
    | LINK prefixPath TO propertyLabelPair #linkPath
    | UNLINK prefixPath FROM propertyLabelPair #unlinkPath
    | SHOW METADATA #showMetadata // not suppert yet
    | DESCRIBE prefixPath #describePath // not suppert yet
    | CREATE INDEX ON timeseriesPath USING function=ID indexWithClause? whereClause? #createIndex //not suppert yet
    | DROP INDEX function=ID ON timeseriesPath #dropIndex //not suppert yet
    | MERGE #mergeStatement //not suppert yet
    | CREATE USER userName=ID password=STRING_LITERAL #createUser
    | ALTER USER userName=ID SET PASSWORD password=STRING_LITERAL #alterUser
    | DROP USER userName=ID #dropUser
    | CREATE ROLE roleName=ID #createRole
    | DROP ROLE roleName=ID #dropRole
    | GRANT USER userName=ID PRIVILEGES privileges ON prefixPath #grantUser
    | GRANT ROLE roleName=ID PRIVILEGES privileges ON prefixPath #grantRole
    | REVOKE USER userName=ID PRIVILEGES privileges ON prefixPath #revokeUser
    | REVOKE ROLE roleName=ID PRIVILEGES privileges ON prefixPath #revokeRole
    | GRANT roleName=ID TO userName=ID #grantRoleToUser
    | REVOKE roleName = ID FROM userName = ID #revokeRoleFromUser
    | LOAD TIMESERIES (fileName=STRING_LITERAL) prefixPath #loadStatement
    | GRANT WATERMARK_EMBEDDING TO rootOrId (COMMA rootOrId)* #grantWatermarkEmbedding
    | REVOKE WATERMARK_EMBEDDING FROM rootOrId (COMMA rootOrId)* #revokeWatermarkEmbedding
    | LIST USER #listUser
    | LIST ROLE #listRole
    | LIST PRIVILEGES USER username=ID ON prefixPath #listPrivilegesUser
    | LIST PRIVILEGES ROLE roleName=ID ON prefixPath #listPrivilegesRole
    | LIST USER PRIVILEGES username = ID #listUserPrivileges
    | LIST ROLE PRIVILEGES roleName = ID #listRolePrivileges
    | LIST ALL ROLE OF USER username = ID #listAllRoleOfUser
    | LIST ALL USER OF ROLE roleName = ID #listAllUserOfRole
    | SET TTL TO path=prefixPath time=INT #setTTLStatement
    | UNSET TTL TO path=prefixPath #unsetTTLStatement
    | SHOW TTL ON prefixPath (COMMA prefixPath)* #showTTLStatement
    | SHOW ALL TTL #showAllTTLStatement
    | LOAD CONFIGURATION #loadConfigurationStatement
    | SELECT INDEX func=ID //not suppert yet
    LR_BRACKET
    p1=timeseriesPath COMMA p2=timeseriesPath COMMA n1=timeValue COMMA n2=timeValue COMMA
    epsilon=constant (COMMA alpha=constant COMMA beta=constant)?
    RR_BRACKET
    fromClause
    whereClause?
    specialClause? #selectIndexStatement //not suppert yet
    | SELECT selectElements
    fromClause
    whereClause?
    specialClause? #selectStatement
    ;

selectElements
    : functionCall (COMMA functionCall)* #functionElement
    | suffixPath (COMMA suffixPath)* #selectElement
    ;

functionCall
    : ID LR_BRACKET suffixPath RR_BRACKET
    ;

attributeClauses
    : DATATYPE OPERATOR_EQ dataType COMMA ENCODING OPERATOR_EQ encoding (COMMA COMPRESSOR OPERATOR_EQ compressor=propertyValue)? (COMMA property)*
    ;

setClause
    : SET setCol (COMMA setCol)*
    ;

whereClause
    : WHERE orExpression
    ;

orExpression
    : andExpression (OPERATOR_OR andExpression)*
    ;

andExpression
    : predicate (OPERATOR_AND predicate)*
    ;

predicate
    : (suffixPath | prefixPath) comparisonOperator constant
    | OPERATOR_NOT? LR_BRACKET orExpression RR_BRACKET
    ;


fromClause
    : FROM prefixPath (COMMA prefixPath)*
    ;

specialClause
    : specialLimit
    | groupByClause specialLimit?
    | fillClause slimitClause? groupByDeviceClause?
    ;

specialLimit
    : limitClause slimitClause? groupByDeviceClause?
    | slimitClause limitClause? groupByDeviceClause?
    | groupByDeviceClause
    ;

limitClause
    : LIMIT INT offsetClause?
    ;

offsetClause
    : OFFSET INT
    ;

slimitClause
    : SLIMIT INT soffsetClause?
    ;

soffsetClause
    : SOFFSET INT
    ;

groupByDeviceClause
    :
    GROUP BY DEVICE
    ;

fillClause
    : FILL LR_BRACKET typeClause (COMMA typeClause)* RR_BRACKET
    ;

groupByClause
    : GROUP BY LR_BRACKET
      DURATION (COMMA timeValue)?
      COMMA timeInterval (COMMA timeInterval)* RR_BRACKET
    ;

typeClause
    : dataType LS_BRACKET linearClause RS_BRACKET
    | dataType LS_BRACKET  previousClause RS_BRACKET
    ;

linearClause
    : LINEAR (COMMA aheadDuration=DURATION COMMA behindDuration=DURATION)?
    ;

previousClause
    : PREVIOUS (COMMA DURATION)?
    ;

indexWithClause
    : WITH indexValue (COMMA indexValue)?
    ;

indexValue
    : ID OPERATOR_EQ INT
    ;


comparisonOperator
    : type = OPERATOR_GT
    | type = OPERATOR_GTE
    | type = OPERATOR_LT
    | type = OPERATOR_LTE
    | type = OPERATOR_EQ
    | type = OPERATOR_NEQ
    ;

insertColumnSpec
    : LR_BRACKET TIMESTAMP (COMMA nodeNameWithoutStar)* RR_BRACKET
    ;

insertValuesSpec
    : LR_BRACKET dateFormat (COMMA constant)* RR_BRACKET
    | LR_BRACKET INT (COMMA constant)* RR_BRACKET
    ;

setCol
    : suffixPath OPERATOR_EQ constant
    ;

privileges
    : STRING_LITERAL (COMMA STRING_LITERAL)*
    ;

rootOrId
    : ROOT
    | ID
    ;

timeInterval
    : LS_BRACKET startTime=timeValue COMMA endTime=timeValue RS_BRACKET
    ;

timeValue
    : dateFormat
    | INT
    ;

propertyValue
    : ID
    | MINUS? INT
    | MINUS? realLiteral
    ;

propertyLabelPair
    : propertyName=ID DOT labelName=ID
    ;

timeseriesPath
    : ROOT (DOT nodeNameWithoutStar)*
    ;

prefixPath
    : ROOT (DOT nodeName)*
    ;

suffixPath
    : nodeName (DOT nodeName)*
    ;

nodeName
    : ID
    | INT
    | STAR
    | STRING_LITERAL
    ;

nodeNameWithoutStar
    : INT
    | ID
    | STRING_LITERAL
    ;

dataType
    : INT32 | INT64 | FLOAT | DOUBLE | BOOLEAN | TEXT
    ;

dateFormat
    : DATETIME
    | NOW LR_BRACKET RR_BRACKET
    ;

constant
    : dateExpression
    | ID
    | MINUS? realLiteral
    | MINUS? INT
    | STRING_LITERAL
    ;

dateExpression
    : dateFormat ((PLUS | MINUS) DURATION)*
    ;

encoding
    : PLAIN | PLAIN_DICTIONARY | RLE | DIFF | TS_2DIFF | GORILLA | REGULAR
    ;

realLiteral
    :   INT DOT (INT | EXPONENT)?
    |   DOT  (INT|EXPONENT)
    |   EXPONENT
    ;

property
    : name=ID OPERATOR_EQ value=propertyValue
    ;

//============================
// Start of the keywords list
//============================
CREATE
    : [Cc] [Rr] [Ee] [Aa] [Tt] [Ee]
    ;

INSERT
    : [Ii] [Nn] [Ss] [Ee] [Rr] [Tt]
    ;

UPDATE
    : [Uu] [Pp] [Dd] [Aa] [Tt] [Ee]
    ;

DELETE
    : [Dd] [Ee] [Ll] [Ee] [Tt] [Ee]
    ;

SELECT
    : [Ss] [Ee] [Ll] [Ee] [Cc] [Tt]
    ;

SHOW
    : [Ss] [Hh] [Oo] [Ww]
    ;

GRANT
    : [Gg] [Rr] [Aa] [Nn] [Tt]
    ;

INTO
    : [Ii] [Nn] [Tt] [Oo]
    ;

SET
    : [Ss] [Ee] [Tt]
    ;

WHERE
    : [Ww] [Hh] [Ee] [Rr] [Ee]
    ;

FROM
    : [Ff] [Rr] [Oo] [Mm]
    ;

TO
    : [Tt] [Oo]
    ;

BY
    : [Bb] [Yy]
    ;

DEVICE
    : [Dd] [Ee] [Vv] [Ii] [Cc] [Ee]
    ;

CONFIGURATION
    : [Cc] [Oo] [Nn] [Ff] [Ii] [Gg] [Uu] [Rr] [Aa] [Tt] [Ii] [Oo] [Nn]
    ;

DESCRIBE
    : [Dd] [Ee] [Ss] [Cc] [Rr] [Ii] [Bb] [Ee]
    ;

SLIMIT
    : [Ss] [Ll] [Ii] [Mm] [Ii] [Tt]
    ;

LIMIT
    : [Ll] [Ii] [Mm] [Ii] [Tt]
    ;

UNLINK
    : [Uu] [Nn] [Ll] [Ii] [Nn] [Kk]
    ;

OFFSET
    : [Oo] [Ff] [Ff] [Ss] [Ee] [Tt]
    ;

SOFFSET
    : [Ss] [Oo] [Ff] [Ff] [Ss] [Ee] [Tt]
    ;

FILL
    : [Ff] [Ii] [Ll] [Ll]
    ;

LINEAR
    : [Ll] [Ii] [Nn] [Ee] [Aa] [Rr]
    ;

PREVIOUS
    : [Pp] [Rr] [Ee] [Vv] [Ii] [Oo] [Uu] [Ss]
    ;

METADATA
    : [Mm] [Ee] [Tt] [Aa] [Dd] [Aa] [Tt] [Aa]
    ;

TIMESERIES
    : [Tt] [Ii] [Mm] [Ee] [Ss] [Ee] [Rr] [Ii] [Ee] [Ss]
    ;

TIMESTAMP
    : [Tt] [Ii] [Mm] [Ee] [Ss] [Tt] [Aa] [Mm] [Pp]
    ;

PROPERTY
    : [Pp] [Rr] [Oo] [Pp] [Ee] [Rr] [Tt] [Yy]
    ;

WITH
    : [Ww] [Ii] [Tt] [Hh]
    ;

ROOT
    : [Rr] [Oo] [Oo] [Tt]
    ;

DATATYPE
    : [Dd] [Aa] [Tt] [Aa] [Tt] [Yy] [Pp] [Ee]
    ;

COMPRESSOR
    : [Cc] [Oo] [Mm] [Pp] [Rr] [Ee] [Ss] [Ss] [Oo] [Rr]
    ;

STORAGE
    : [Ss] [Tt] [Oo] [Rr] [Aa] [Gg] [Ee]
    ;

GROUP
    : [Gg] [Rr] [Oo] [Uu] [Pp]
    ;

LABEL
    : [Ll] [Aa] [Bb] [Ee] [Ll]
    ;

INT32
    : [Ii] [Nn] [Tt] '3' '2'
    ;

INT64
    : [Ii] [Nn] [Tt] '6' '4'
    ;

FLOAT
    : [Ff] [Ll] [Oo] [Aa] [Tt]
    ;

DOUBLE
    : [Dd] [Oo] [Uu] [Bb] [Ll] [Ee]
    ;

BOOLEAN
    : [Bb] [Oo] [Oo] [Ll] [Ee] [Aa] [Nn]
    ;

TEXT
    : [Tt] [Ee] [Xx] [Tt]
    ;

ENCODING
    : [Ee] [Nn] [Cc] [Oo] [Dd] [Ii] [Nn] [Gg]
    ;

PLAIN
    : [Pp] [Ll] [Aa] [Ii] [Nn]
    ;

PLAIN_DICTIONARY
    : [Pp] [Ll] [Aa] [Ii] [Nn] '_' [Dd] [Ii] [Cc] [Tt] [Ii] [Oo] [Nn] [Aa] [Rr] [Yy]
    ;

RLE
    : [Rr] [Ll] [Ee]
    ;

DIFF
    : [Dd] [Ii] [Ff] [Ff]
    ;

TS_2DIFF
    : [Tt] [Ss] '_' '2' [Dd] [Ii] [Ff] [Ff]
    ;

GORILLA
    : [Gg] [Oo] [Rr] [Ii] [Ll] [Ll] [Aa]
    ;


REGULAR
    : [Rr] [Ee] [Gg] [Uu] [Ll] [Aa] [Rr]
    ;

BITMAP
    : [Bb] [Ii] [Tt] [Mm] [Aa] [Pp]
    ;

ADD
    : [Aa] [Dd] [Dd]
    ;

VALUES
    : [Vv] [Aa] [Ll] [Uu] [Ee] [Ss]
    ;

NOW
    : [Nn] [Oo] [Ww]
    ;

LINK
    : [Ll] [Ii] [Nn] [Kk]
    ;

INDEX
    : [Ii] [Nn] [Dd] [Ee] [Xx]
    ;

USING
    : [Uu] [Ss] [Ii] [Nn] [Gg]
    ;

ON
    : [Oo] [Nn]
    ;

DROP
    : [Dd] [Rr] [Oo] [Pp]
    ;

MERGE
    : [Mm] [Ee] [Rr] [Gg] [Ee]
    ;

LIST
    : [Ll] [Ii] [Ss] [Tt]
    ;

USER
    : [Uu] [Ss] [Ee] [Rr]
    ;

PRIVILEGES
    : [Pp] [Rr] [Ii] [Vv] [Ii] [Ll] [Ee] [Gg] [Ee] [Ss]
    ;

ROLE
    : [Rr] [Oo] [Ll] [Ee]
    ;

ALL
    : [Aa] [Ll] [Ll]
    ;

OF
    : [Oo] [Ff]
    ;

ALTER
    : [Aa] [Ll] [Tt] [Ee] [Rr]
    ;

PASSWORD
    : [Pp] [Aa] [Ss] [Ss] [Ww] [Oo] [Rr] [Dd]
    ;

REVOKE
    : [Rr] [Ee] [Vv] [Oo] [Kk] [Ee]
    ;

LOAD
    : [Ll] [Oo] [Aa] [Dd]
    ;

WATERMARK_EMBEDDING
    : [Ww] [Aa] [Tt] [Ee] [Rr] [Mm] [Aa] [Rr] [Kk] '_' [Ee] [Mm] [Bb] [Ee] [Dd] [Dd] [Ii] [Nn] [Gg]
    ;

UNSET
    : [Uu] [Nn] [Ss] [Ee] [Tt]
    ;

TTL
    : [Tt] [Tt] [Ll]
    ;
//============================
// End of the keywords list
//============================
COMMA : ',';

STAR : '*';

OPERATOR_EQ : '=' | '==';

OPERATOR_GT : '>';

OPERATOR_GTE : '>=';

OPERATOR_LT : '<';

OPERATOR_LTE : '<=';

OPERATOR_NEQ : '!=' | '<>';

OPERATOR_AND
    : [Aa] [Nn] [Dd]
    | '&'
    | '&&'
    ;

OPERATOR_OR
    : [Oo] [Rr]
    | '|'
    | '||'
    ;

OPERATOR_NOT
    : [Nn] [Oo] [Tt] | '!'
    ;

MINUS : '-';

PLUS : '+';

DOT : '.';

LR_BRACKET : '(';

RR_BRACKET : ')';

LS_BRACKET : '[';

RS_BRACKET : ']';

L_BRACKET : '{';

R_BRACKET : '}';

STRING_LITERAL
   : DOUBLE_QUOTE_STRING_LITERAL
   | SINGLE_QUOTE_STRING_LITERAL
   ;

INT : [0-9]+;

EXPONENT : INT ('e'|'E') ('+'|'-')? INT ;

DURATION
    :
    (INT+ ([Yy]|[Mm] [Oo]|[Ww]|[Dd]|[Hh]|[Mm]|[Ss]|[Mm] [Ss]|[Uu] [Ss]|[Nn] [Ss]))+
    ;

DATETIME
    : INT ('-'|'/') INT ('-'|'/') INT
      ([Tt] | WS)
      INT ':' INT ':' INT (DOT INT)?
      (('+' | '-') INT ':' INT)?
    ;
/** Allow unicode rule/token names */
ID			:	('a'..'z'|'A'..'Z'|'_') ('a'..'z'|'A'..'Z'|'0'..'9'|'_'|'-')*;

//support non English language
//fragment
//NameChar
//	:   NameStartChar
//	|   '0'..'9'
//	|   '_'
//	|   '\u00B7'
//	|   '\u0300'..'\u036F'
//	|   '\u203F'..'\u2040'
//	;
//
//fragment
//NameStartChar
//	:   'A'..'Z'
//	|   'a'..'z'
//	|   '\u00C0'..'\u00D6'
//	|   '\u00D8'..'\u00F6'
//	|   '\u00F8'..'\u02FF'
//	|   '\u0370'..'\u037D'
//	|   '\u037F'..'\u1FFF'
//	|   '\u200C'..'\u200D'
//	|   '\u2070'..'\u218F'
//	|   '\u2C00'..'\u2FEF'
//	|   '\u3001'..'\uD7FF'
//	|   '\uF900'..'\uFDCF'
//	|   '\uFDF0'..'\uFFFD'
//	; // ignores | ['\u10000-'\uEFFFF] ;

fragment DOUBLE_QUOTE_STRING_LITERAL
	:	'"' ('\\' . | ~'"' )*? '"'
	;

fragment SINGLE_QUOTE_STRING_LITERAL
  : '\'' ('\\' . | ~'\'' )*? '\''
  ;

WS
    : [ \r\n\t]+ -> channel(HIDDEN)
    ;

ErrorChar
    :.
    ;