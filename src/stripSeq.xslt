<?xml version="1.0"?>

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:tei="http://www.tei-c.org/ns/1.0">

    <xsl:output method="xml" encoding="UTF-8" indent="yes" omit-xml-declaration="yes"/>

    <xsl:strip-space elements="*"/>

    <xsl:template match="tei:seg"><xsl:text> </xsl:text></xsl:template>


    <xsl:template match="tei:pb"><xsl:text> </xsl:text></xsl:template>


    <xsl:template match="tei:hi"><xsl:copy-of select="text()"/></xsl:template>

    <xsl:template match="tei:lb"><xsl:copy-of select="text()"/></xsl:template>



    <!--    There is a built-in template rule to allow recursive processing to continue in the absence of a successful pattern match by an explicit template rule in the stylesheet. This template rule applies to both element nodes and the root node. The following shows the equivalent of the built-in template rule:-->
    <xsl:template match="@*|node()">
        <xsl:copy >
        <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>


    <!--    There is also a built-in template rule for text and attribute nodes that copies text through:-->
    <xsl:template match="text()">
        <xsl:copy>
                <xsl:value-of select="."/>
        </xsl:copy>

    </xsl:template>

    <!--    The built-in template rule for processing instructions and comments is to do nothing.-->
    <xsl:template match="processing-instruction()|comment()"/>

    <!--    The built-in template rule for namespace nodes is also to do nothing. There is no pattern that can match a namespace node; so, the built-in template rule is the only template rule that is applied for namespace nodes.-->

    <!--    The built-in template rules are treated as if they were imported implicitly before the stylesheet and so have lower import precedence than all other template rules. Thus, the author can override a built-in template rule by including an explicit template rule.-->

</xsl:stylesheet>