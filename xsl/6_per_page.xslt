<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <!-- output method -->
    <xsl:output method="xml" omit-xml-declaration="yes" cdata-section-elements="" encoding="utf-8" media-type="text/xml" indent="yes" version="1.0"/>

    <!-- root template -->
    <xsl:template match="/">
        <html xmlns="http://www.w3.org/1999/xhtml">
        <head>
            <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
            <title>Task cards</title>
            <link rel="stylesheet" type="text/css" href="css/6_per_page.css" />
        </head>
        <body>
            <table class="all">
                <xsl:for-each select="rss/channel/item">
                    <xsl:if test="position() mod 2 = 1">
                        <xsl:variable name="tr_open">
                            <xsl:if test="position() mod 6 = 1 and position() != 1">&lt;tr class=&quot;page-break&quot;&gt;</xsl:if>
                            <xsl:if test="position() mod 6 != 1">&lt;tr&gt;</xsl:if>
                        </xsl:variable>
                        <xsl:value-of select="$tr_open" disable-output-escaping="yes"/>
                    </xsl:if>

                    <td>
                        <div class="card-wrapper">
                            <xsl:call-template name="card" >
                                <xsl:with-param name="data" select="." />
                            </xsl:call-template>
                        </div>
                    </td>

                    <xsl:if test="position() mod 2 = 0">
                        <xsl:variable name="tr_close">&lt;/tr&gt;</xsl:variable>
                        <xsl:value-of select="$tr_close" disable-output-escaping="yes"/>
                    </xsl:if>

                </xsl:for-each>
            </table>
        </body>
        </html>
    </xsl:template>

    <xsl:template name="card">
        <xsl:param name="data"/>
        <table class="card">
            <tr>
                <td>
                    <h1><xsl:value-of select="$data/key" /></h1>
                    <xsl:if test="$data/parent">
                        Subtask of <strong><xsl:value-of select="$data/parent" /></strong>
                    </xsl:if>
                </td>
                <td class="meta">
                    Version: <span class="version"><xsl:value-of select="$data/fixVersion" /></span><br />
                    Priority: <img src="{$data/priority/@iconUrl}" style="position: relative; top: 3px"/> <span class="priority"><xsl:value-of select="$data/priority" /></span>
                </td>
            </tr>
            <tr class="summary">
                <td colspan="2"><xsl:value-of select="$data/summary" /></td>
            </tr>
            <xsl:if test="$data/timeestimate or $data/customfields/customfield[@id='customfield_10040']/customfieldvalues[1]/customfieldvalue">
                <tr class="estimation">
                    <td colspan="2">Estimation:
                        <span class="estimation">
                            <xsl:choose>
                                <xsl:when test="$data/timeestimate">
                                    <xsl:value-of select="$data/timeestimate" />
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="$data/customfields/customfield[@id='customfield_10040']/customfieldvalues[1]/customfieldvalue" /> SP
                                </xsl:otherwise>
                            </xsl:choose>
                        </span>
                    </td>
                </tr>
            </xsl:if>
            <tr class="description">
                <td colspan="2"><xsl:value-of select="$data/description" disable-output-escaping="yes"/></td>
            </tr>
        </table>

    </xsl:template>

</xsl:stylesheet>
