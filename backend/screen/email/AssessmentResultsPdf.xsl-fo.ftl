
<!--
XSL-FO template for Assessment Results PDF
Matches design from assessment_results_screen.dart
-->
<fo:root xmlns:fo="http://www.w3.org/1999/XSL/Format" font-family="Helvetica, Arial, sans-serif">
    <fo:layout-master-set>
        <fo:simple-page-master master-name="main" page-height="29.7cm" page-width="21cm"
                               margin-top="1.5cm" margin-bottom="1.5cm"
                               margin-left="2cm" margin-right="2cm">
            <fo:region-body margin-top="0.5in" margin-bottom="0.5in"/>
            <fo:region-before extent="0.5in"/>
            <fo:region-after extent="0.5in"/>
        </fo:simple-page-master>
    </fo:layout-master-set>

    <fo:page-sequence master-reference="main">
        <!-- Header -->
        <fo:static-content flow-name="xsl-region-before">
            <fo:block text-align="center" font-size="10pt" color="#718096">
                ${(assessmentName!"")?xml} - Assessment Results
            </fo:block>
        </fo:static-content>

        <!-- Footer -->
        <fo:static-content flow-name="xsl-region-after">
            <fo:block text-align="center" font-size="9pt" color="#718096">
                Generated on ${ec.l10n.format(ec.user.nowTimestamp, 'MMMM d, yyyy')} | © GrowERP
            </fo:block>
        </fo:static-content>

        <!-- Main Content -->
        <fo:flow flow-name="xsl-region-body">
            
            <!-- Title Section with Gradient Effect -->
            <fo:block background-color="#667EEA" color="white" 
                      padding="20pt" margin-bottom="15pt">
                <fo:block font-size="24pt" font-weight="bold" margin-bottom="8pt">
                    Assessment Results
                </fo:block>
                <fo:block font-size="14pt">
                    ${(respondentName!"")?xml}
                </fo:block>
            </fo:block>

            <!-- Score Card -->
            <fo:block background-color="#F7FAFC" border="1pt solid #E2E8F0" 
                      padding="20pt" margin-bottom="15pt">
                <fo:block text-align="center">
                    <fo:block font-size="16pt" font-weight="bold" color="#2D3748" margin-bottom="10pt">
                        Your Score
                    </fo:block>
                    <fo:block font-size="48pt" font-weight="bold" color="#667EEA" margin-bottom="5pt">
                        ${score!0}
                    </fo:block>
                    <fo:block font-size="14pt" color="#718096">
                        out of ${maxScore!0} (${percentage!0}%)
                    </fo:block>
                </fo:block>
            </fo:block>

            <!-- Advice Card -->
            <fo:block background-color="#FFF" border="2pt solid #667EEA" 
                      padding="20pt" margin-bottom="15pt">
                <fo:block font-size="18pt" font-weight="bold" color="#2D3748" margin-bottom="10pt">
                    Assessment Feedback
                </fo:block>
                <fo:block font-size="12pt" color="#4A5568" margin-bottom="10pt" line-height="1.6">
                    Status: <fo:inline font-weight="bold" color="#667EEA">${(leadStatus!"")?xml}</fo:inline>
                </fo:block>
                <fo:block font-size="11pt" color="#4A5568" line-height="1.6">
                    ${(adviceDescription!"")?has_content?then((adviceDescription!"")?xml, 'Thank you for completing the assessment. Your results have been recorded.')}
                </fo:block>
            </fo:block>

            <!-- Questions and Answers -->
            <fo:block background-color="#F7FAFC" border="1pt solid #E2E8F0"
                      padding="20pt" margin-bottom="15pt">
                <fo:block font-size="16pt" font-weight="bold" color="#2D3748" margin-bottom="15pt">
                    Your Answers
                </fo:block>
                
                <#if questionsWithAnswers?? && questionsWithAnswers?has_content>
                    <#list questionsWithAnswers as qa>
                <fo:block margin-bottom="12pt" padding-bottom="10pt" border-bottom="1pt solid #E2E8F0">
                    <fo:block font-size="11pt" font-weight="bold" color="#2D3748" margin-bottom="4pt">
                        ${qa.questionSequence!0}. ${(qa.questionText!"")?xml}
                    </fo:block>
                    <fo:block font-size="10pt" color="#667EEA" margin-left="15pt">
                        - ${(qa.selectedAnswer!"")?xml} <#if qa.optionScore?? && (qa.optionScore > 0)>(+${qa.optionScore} points)</#if>
                    </fo:block>
                </fo:block>
                    </#list>
                <#else>
                <fo:block font-size="11pt" color="#718096">
                    No answer details available.
                </fo:block>
                </#if>
            </fo:block>

            <!-- Summary -->
            <fo:block background-color="#F7FAFC" border="1pt solid #E2E8F0"
                      padding="20pt" margin-bottom="15pt">
                <fo:block font-size="16pt" font-weight="bold" color="#2D3748" margin-bottom="15pt">
                    Summary
                </fo:block>
                
                <fo:block font-size="11pt" color="#4A5568" line-height="1.8">
                    Completed: <#if createdDate??>${ec.l10n.format(createdDate, 'MMM d, yyyy h:mm a')}<#else>N/A</#if>
                </fo:block>
                <fo:block font-size="11pt" color="#4A5568" line-height="1.8" margin-top="5pt">
                    Result ID: ${(assessmentResultId!"")?xml}
                </fo:block>
            </fo:block>

            <!-- Summary Section -->
            <fo:block background-color="#EBF4FF" border="1pt solid #BEE3F8"
                      padding="15pt" margin-top="20pt">
                <fo:block font-size="10pt" color="#2C5282" line-height="1.6">
                    <fo:inline font-weight="bold">Note:</fo:inline> This assessment provides insights based on your responses. 
                    If you have questions about your results, please contact support@growerp.com.
                </fo:block>
            </fo:block>

            <!-- Contact Information -->
            <fo:block margin-top="30pt" text-align="center" font-size="9pt" color="#A0AEC0">
                <fo:block>GrowERP Assessment System</fo:block>
                <fo:block>www.growerp.com | support@growerp.com</fo:block>
            </fo:block>

        </fo:flow>
    </fo:page-sequence>
</fo:root>
