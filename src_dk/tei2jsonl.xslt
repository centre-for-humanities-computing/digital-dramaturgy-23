<?xml version="1.0"?>

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:tei="http://www.tei-c.org/ns/1.0">

    <xsl:output method="text" encoding="UTF-8" indent="no" omit-xml-declaration="yes"/>
    <xsl:strip-space elements="*"/>

    <!--    Output will have these columns
    type, docTitle, year, title, act, act_number, scene, scene_number, index, speaker_stage, speaker, spoke, stage

    type is the type of expression. For debug purposes currently, do not use

    year is year

    docTitle is the full title
    title is the first part of the title

    act and scene are hopefully easily understood
    act_number and scene_number are the numeric versions of act and scene

    index is counter (inside the scene, it resets with each new scene)

    speaker_stage is extra instructions to the speaker. If present, speaker will also be present

    speaker is the role speaking.

    spoke is what he said. If present, speaker will also be present

    stage is actual stage instructions, likely names of roles that should appear on stage

    -->


    <xsl:template name="lg">
        <!--Preserve linebreaks in lg blocks        -->
        <xsl:for-each select="../tei:l">
            <xsl:if test="@rend='indent'">
                <xsl:text>\t</xsl:text>
            </xsl:if>
            <xsl:value-of select="normalize-space(.)"/>
            <xsl:text>\n</xsl:text>
        </xsl:for-each>
    </xsl:template>


    <xsl:template name="act_number">
        <xsl:number count="//tei:body/tei:div"/>
    </xsl:template>


    <xsl:template name="scene_number">
        <xsl:number count="//tei:div"/>
    </xsl:template>

    <xsl:template name="scene_index">
        <xsl:number level="any" from="//tei:div"
                    count="
                        tei:stage |
                        tei:sp/tei:stage |
                        tei:sp/tei:speaker/tei:stage |
                        tei:sp/tei:p |
                        tei:sp/tei:lg |
                        tei:sp/tei:p/tei:stage"/>
    </xsl:template>

    <xsl:variable name="docTitle">
        <xsl:for-each
                select="//tei:titlePart">
            <xsl:value-of select="normalize-space(text())"/>
            <xsl:if test="position() != last()">
                <xsl:text> </xsl:text>
            </xsl:if>
        </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="firstTitle">
        <xsl:for-each
                select="//tei:titlePart[1]">
            <xsl:value-of select="normalize-space(text())"/>
            <xsl:if test="position() != last()">
                <xsl:text> </xsl:text>
            </xsl:if>
        </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="year"
                  select="normalize-space(translate(/tei:TEI/tei:text/tei:front/tei:titlePage/tei:byline/text(),'&#xA;',''))"/>

    <xsl:template name="furthest_name">
        <!--Find the tei:div name attribute that is furthest from the current node. This is always the act name-->
        <xsl:value-of select="(ancestor-or-self::tei:div[@n]/@n)[1]"/>
    </xsl:template>

    <xsl:template name="nearest_name">
        <!--Find the tei:div name attribute that is nearest to the current node. This is always the scene name-->
        <xsl:value-of select="(ancestor-or-self::tei:div[@n]/@n)[last()]"/>
    </xsl:template>


    <xsl:template match="tei:publicationStmt"/>
    <!-- TODO: The title field need all parts of the titlePart -->
    <!-- In the year filed, we need to remove newlines, done with translate(),
         and the also to remove instances of munltiple spaces, done using normalize-space()
    -->
    <xsl:template match="//tei:stage" name="stage">
        <xsl:variable name="depth" select="."/>
        <xsl:variable name="line">
            {"type": 1,
            "docTitle": "<xsl:value-of select="$docTitle"/>",
            "year": "<xsl:value-of select="$year"/>",
            "title": "<xsl:value-of select="$firstTitle"/>",
            "act":  "<xsl:call-template name="furthest_name"/>",
            "act_number": <xsl:call-template name="act_number"/>,
            "scene": "<xsl:call-template name="nearest_name"/>",
            "scene_number": <xsl:call-template name="scene_number"/>,
            "index": <xsl:call-template name="scene_index"/>,

            "speaker_stage": null,
            "speaker": null,
            "spoke": null,

            "stage": "<xsl:value-of select="normalize-space(.)"/>"
            }
        </xsl:variable>
        <xsl:value-of select="normalize-space($line)"/><xsl:text>&#xa;</xsl:text>
    </xsl:template>

    <xsl:template match="//tei:sp/tei:stage" name="speaker">
        <xsl:variable name="line">
            {"type": 2,
            "docTitle": "<xsl:value-of select="$docTitle"/>",
            "year": "<xsl:value-of select="$year"/>",
            "title": "<xsl:value-of select="$firstTitle"/>",
            "act":  "<xsl:call-template name="furthest_name"/>",
            "act_number": <xsl:call-template name="act_number"/>,
            "scene": "<xsl:call-template name="nearest_name"/>",
            "scene_number": <xsl:call-template name="scene_number"/>,
            "index": <xsl:call-template name="scene_index"/>,

            "speaker_stage": null,
            "speaker": "<xsl:value-of select="normalize-space(../tei:speaker/text())"/>",
            "spoke": null,

            "stage": "<xsl:value-of select="normalize-space(.)"/>"
            }
        </xsl:variable>
        <xsl:value-of select="normalize-space($line)"/><xsl:text>&#xa;</xsl:text>
    </xsl:template>

    <xsl:template match="//tei:sp/tei:speaker/tei:stage" name="speaker_stage">
        <xsl:variable name="line">
            {"type": 3,
            "docTitle": "<xsl:value-of select="$docTitle"/>",
            "year": "<xsl:value-of select="$year"/>",
            "title": "<xsl:value-of select="$firstTitle"/>",
            "act":  "<xsl:call-template name="furthest_name"/>",
            "act_number": <xsl:call-template name="act_number"/>,
            "scene": "<xsl:call-template name="nearest_name"/>",
            "scene_number": <xsl:call-template name="scene_number"/>,
            "index": <xsl:call-template name="scene_index"/>,


            "speaker_stage": "<xsl:value-of select="normalize-space(.)"/>",
            "speaker": "<xsl:value-of select="normalize-space(../../tei:speaker/text())"/>",
            "spoke": null,

            "stage": null
            }
        </xsl:variable>
        <xsl:value-of select="normalize-space($line)"/><xsl:text>&#xa;</xsl:text>
    </xsl:template>

    <xsl:template match="//tei:sp/tei:p/text()[count(preceding-sibling::*)=0]" name="speaker_spoke">
        <xsl:variable name="line">
            {"type": 4,
            "docTitle": "<xsl:value-of select="$docTitle"/>",
            "year": "<xsl:value-of select="$year"/>",
            "title": "<xsl:value-of select="$firstTitle"/>",
            "act":  "<xsl:call-template name="furthest_name"/>",
            "act_number": <xsl:call-template name="act_number"/>,
            "scene": "<xsl:call-template name="nearest_name"/>",
            "scene_number": <xsl:call-template name="scene_number"/>,
            "index": <xsl:call-template name="scene_index"/>,

            "speaker_stage": null,
            "speaker": "<xsl:value-of select="normalize-space(../../tei:speaker/text())"/>",
            "spoke": "<xsl:value-of select="normalize-space(.)"/>",

            "stage": null
            }
        </xsl:variable>
        <xsl:value-of select="normalize-space($line)"/><xsl:text>&#xa;</xsl:text>
    </xsl:template>

    <xsl:template match="//tei:sp/tei:lg/tei:l[count(preceding-sibling::*)=0]" name="speaker_spoke_lg">
        <xsl:variable name="line">
            {"type": 5,
            "docTitle": "<xsl:value-of select="$docTitle"/>",
            "year": "<xsl:value-of select="$year"/>",
            "title": "<xsl:value-of select="$firstTitle"/>",
            "act":  "<xsl:call-template name="furthest_name"/>",
            "act_number": <xsl:call-template name="act_number"/>,
            "scene": "<xsl:call-template name="nearest_name"/>",
            "scene_number": <xsl:call-template name="scene_number"/>,
            "index": <xsl:call-template name="scene_index"/>,

            "speaker_stage": null,
            "speaker": "<xsl:value-of select="normalize-space(../../tei:speaker/text())"/>",
            "spoke": "<xsl:call-template name="lg"/>",

            "stage": null
            }
        </xsl:variable>
        <xsl:value-of select="normalize-space($line)"/><xsl:text>&#xa;</xsl:text>
    </xsl:template>

    <xsl:template match="//tei:sp/tei:p/tei:stage" name="speaker_spoke_multiline">
        <xsl:variable name="line">
            {"type": 6,
            "docTitle": "<xsl:value-of select="$docTitle"/>",
            "year": "<xsl:value-of select="$year"/>",
            "title": "<xsl:value-of select="$firstTitle"/>",
            "act":  "<xsl:call-template name="furthest_name"/>",
            "act_number": <xsl:call-template name="act_number"/>,
            "scene": "<xsl:call-template name="nearest_name"/>",
            "scene_number": <xsl:call-template name="scene_number"/>,
            "index": <xsl:call-template name="scene_index"/>,

            "speaker_stage": "<xsl:value-of select="normalize-space(.)"/>",
            "speaker": "<xsl:value-of select="normalize-space(../../tei:speaker/text())"/>",
            <xsl:choose>
                <xsl:when test="position() != last()">
                    "spoke": "<xsl:value-of select="normalize-space(following-sibling::text())"/>",
                </xsl:when>
                <xsl:otherwise>
                    "spoke": null,
                </xsl:otherwise>
            </xsl:choose>

            "stage": null
            }
        </xsl:variable>
        <xsl:value-of select="normalize-space($line)"/><xsl:text>&#xa;</xsl:text>
    </xsl:template>


    <!--    There is a built-in template rule to allow recursive processing to continue in the absence of a successful pattern match by an explicit template rule in the stylesheet. This template rule applies to both element nodes and the root node. The following shows the equivalent of the built-in template rule:-->
    <xsl:template match="*|/">
        <xsl:apply-templates/>
    </xsl:template>

    <!--    There is also a built-in template rule for each mode, which allows recursive processing to continue in the same mode in the absence of a successful pattern match by an explicit template rule in the stylesheet. This template rule applies to both element nodes and the root node. The following shows the equivalent of the built-in template rule for mode m.-->
    <xsl:template match="*|/" mode="m">
        <xsl:apply-templates mode="m"/>
    </xsl:template>

    <!--    There is also a built-in template rule for text and attribute nodes that copies text through:-->
    <xsl:template match="text()|@*">
        <!--        <xsl:value-of select="."/>-->
    </xsl:template>

    <!--    The built-in template rule for processing instructions and comments is to do nothing.-->
    <xsl:template match="processing-instruction()|comment()"/>

    <!--    The built-in template rule for namespace nodes is also to do nothing. There is no pattern that can match a namespace node; so, the built-in template rule is the only template rule that is applied for namespace nodes.-->

    <!--    The built-in template rules are treated as if they were imported implicitly before the stylesheet and so have lower import precedence than all other template rules. Thus, the author can override a built-in template rule by including an explicit template rule.-->

</xsl:stylesheet>