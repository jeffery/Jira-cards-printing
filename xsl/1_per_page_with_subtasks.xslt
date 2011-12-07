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
            <link rel="stylesheet" type="text/css" href="css/1_per_page_with_subtasks.css" />
        </head>
        <body>
            <xsl:for-each select="rss/channel/item">
                <xsl:variable name="tr_open">
                    <xsl:if test="position() != 1">&lt;div class=&quot;page-break&quot;&gt;</xsl:if>
                    <xsl:if test="position() = 1">&lt;div&gt;</xsl:if>
                </xsl:variable>
                <xsl:value-of select="$tr_open" disable-output-escaping="yes"/>
                    <div class="card-wrapper">
                        <xsl:call-template name="card" >
                            <xsl:with-param name="data" select="." />
                        </xsl:call-template>
                    </div>
                <xsl:variable name="tr_close">&lt;/div&gt;</xsl:variable>
                <xsl:value-of select="$tr_close" disable-output-escaping="yes"/>
            </xsl:for-each>
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
                    <table>
                        <tr>
                            <td>
                                Version:
                                <xsl:for-each select="$data/fixVersion">
                                    <span class="version"><xsl:value-of select="." /></span>
                                    <xsl:if test="position() != last()">
                                        <xsl:text>, </xsl:text>
                                    </xsl:if>
                                </xsl:for-each>
                                <br />
                                Priority: <img src="{$data/priority/@iconUrl}" style="position: relative; top: 3px"/>
                                    <span class="priority">
                                        <xsl:choose>
                                            <xsl:when test="$data/priority/@id = 2">Must</xsl:when>
                                            <xsl:when test="$data/priority/@id = 3">Should</xsl:when>
                                            <xsl:when test="$data/priority/@id = 4">Could</xsl:when>
                                        </xsl:choose>
                                    </span><br />
                                Type: <span class="type"><xsl:value-of select="$data/type" /></span>
                            </td>
                            <td>
                                <span class="storypoints">
                                    <xsl:if test="$data/customfields/customfield[@id='customfield_10040']/customfieldvalues[1]/customfieldvalue">
                                        <xsl:value-of select="floor($data/customfields/customfield[@id='customfield_10040']/customfieldvalues[1]/customfieldvalue)" /> SP
                                    </xsl:if>
                                    <xsl:if test="$data/timeoriginalestimate and not($data/customfields/customfield[@id='customfield_10040']/customfieldvalues[1]/customfieldvalue)">
                                        <xsl:value-of select="$data/timeoriginalestimate" />
                                    </xsl:if>
                                </span>
                            </td>
                        </tr>
                    </table>
                </td>
            </tr>
            <xsl:if test="$data/labels">
                <tr class="labels">
                    <td colspan="2">
                        Labels:
                        <xsl:for-each select="$data/labels">
                            <xsl:value-of select="." /><xsl:text> </xsl:text>
                        </xsl:for-each>
                    </td>
                </tr>
            </xsl:if>
            <tr class="summary">
                <td colspan="2"><xsl:value-of select="$data/summary" /></td>
            </tr>
            <xsl:if test="$data/issuelinks/issuelinktype">
                <tr class="links">
                    <td>
                        <strong>Links: </strong><br />
                        <xsl:for-each select="$data/issuelinks/issuelinktype">
                            <xsl:if test="./outwardlinks">
                                <xsl:value-of select="./name" />: <xsl:value-of select="./outwardlinks/@description" /><xsl:text> </xsl:text><strong><xsl:value-of select="./outwardlinks/issuelink/issuekey" /></strong><br />
                            </xsl:if>
                            <xsl:if test="./inwardlinks">
                                <xsl:value-of select="./name" />: <xsl:value-of select="./inwardlinks/@description" /><xsl:text> </xsl:text><strong><xsl:value-of select="./inwardlinks/issuelink/issuekey" /></strong><br />
                            </xsl:if>
                        </xsl:for-each>
                    </td>
                </tr>
            </xsl:if>
            <xsl:if test="$data/subtasks/subtask">
                <tr class="subtasks">
                    <td colspan="2">
                        <h3>Subtasks</h3>
                        <table>
                            <tr>
                                <th></th>
                                <th></th>
                                <th>done</th>
                            </tr>
                            <xsl:for-each select="$data/subtasks/subtask">

                                <tr>
                                    <xsl:if test="position() mod 2 = 1">
                                        <xsl:attribute name="class">
                                            <xsl:text>odd</xsl:text>
                                        </xsl:attribute>
                                    </xsl:if>
                                    <td class="type">
                                        <img src="{./item/type/@iconUrl}" />
                                    </td>
                                    <td>
                                        <span class="summary"><xsl:value-of select="./item/summary" /></span>
                                    </td>
                                    <td class="done">
                                        <input type="checkbox">
                                            <xsl:if test="./item/status/@id = 5">
                                                <xsl:attribute name="checked" select="checked" />
                                            </xsl:if>
                                        </input>
                                    </td>
                                </tr>
                            </xsl:for-each>
                        </table>
                    </td>
                </tr>
            </xsl:if>


            <tr class="description">
                <td colspan="2"><xsl:value-of select="$data/description" disable-output-escaping="yes"/></td>
            </tr>
        </table>

    </xsl:template>

</xsl:stylesheet>
