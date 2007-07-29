#
# SyntaxDocumentation.rb - TaskJuggler
#
# Copyright (c) 2006, 2007 by Chris Schlaeger <cs@kde.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.
#
# $Id$
#

class KeywordDocumentation

  attr_reader :keyword, :pattern
  attr_accessor :contexts, :scenarioSpecific

  def initialize(rule, pattern, syntax, args, optAttrPatterns)
    @rule = rule
    @pattern = pattern
    @keyword = pattern.keyword
    @syntax = syntax
    @args = args.uniq
    # Hash that maps patterns of optional attributes to a boolean value. True
    # if the pattern is a scenario specific attribute.
    @optAttrPatterns = optAttrPatterns
    # The above hash is later converted into a list that points to the keyword
    # documentation of the optional attribute.
    @optionalAttributes = []
    @scenarioSpecific = false
    @inheritable = false
    @contexts = []
    @seeAlso = []
  end

  def crossReference(keywords, rules)
    @args.each do |arg|
      if arg.text[0] == ?^
        keyword = arg.text.slice(1, arg.text.length - 1)
        raise "Unknown reference #{keyword}" if keywords[keyword].nil?
        @optAttrPatterns[keywords[keyword].pattern] = false
      end
    end

    @optAttrPatterns.each do |pattern, scenarioSpecific|
      token = pattern.terminalToken(rules)
      if pattern.keyword.nil?
        puts "Pattern #{pattern} has no keyword defined"
        next
      end
      if (kwd = keywords[pattern.keyword]).nil?
        puts "Keyword #{keyword} has undocumented optional attribute " +
             "#{token[0]}"
      else
        @optionalAttributes << kwd
        kwd.contexts << self
        kwd.scenarioSpecific = true if scenarioSpecific
      end
    end

    @pattern.seeAlso.sort.each do |also|
      if keywords[also].nil?
        raise "See also reference #{also} of #{@pattern} is unknown"
      end
      @seeAlso << keywords[also]
    end
  end

  def to_s
    tagW = 13
    textW = 79 - tagW

    # Top line with multiple elements
    str = "Keyword:     #{@keyword}     " +
          "Scenario Specific: #{@scenarioSpecific ? 'Yes' : 'No'}     " +
          "Inheriable: #{@inheritable ? 'Yes' : 'No'}\n\n"

    str += "Purpose:     #{format(tagW, @pattern.doc, textW)}\n\n"

    str += "Syntax:      #{format(tagW, @syntax, textW)}\n\n"

    str += "Arguments:   "
    if @args.empty?
      str += format(tagW, "none\n\n", textW)
    else
      argStr = ''
      @args.each do |arg|
        unless arg.syntax.empty?
          typeSpec = arg.syntax
          typeSpec[0] = '['
          typeSpec[-1] = ']'
          indent = arg.name.length + arg.syntax.length + 3
          argStr += "#{arg.name} #{arg.syntax}: " +
                    "#{format(indent, arg.text, textW - indent)}\n\n"
        else
          indent = arg.name.length + 2
          text = arg.text.clone
          if text[0] == ?^
            keyword = text.slice(1, text.length - 1)
            text = "Comma separated list. See #{keyword} for details."
          end
          argStr += "#{arg.name}: " +
                    "#{format(indent, text, textW - indent)}\n\n"
        end
      end
      str += format(tagW, argStr, textW)
    end

    str += "Context:     "
    if @contexts.empty?
      str += format(tagW, "Global scope", textW)
    else
      cxtStr = ''
      @contexts.each do |context|
        unless cxtStr.empty?
          cxtStr += ', '
        end
        cxtStr += context.keyword
      end
      str += format(tagW, cxtStr, textW)
    end

    str += "\n\nAttributes:  "
    if @optionalAttributes.empty?
      str += "none\n\n"
    else
      attrStr = ''
      @optionalAttributes.sort! do |a, b|
        a.keyword <=> b.keyword
      end
      @optionalAttributes.each do |attr|
        unless attrStr.empty?
          attrStr += ', '
        end
        attrStr += '[sc:]' if attr.scenarioSpecific
        attrStr += attr.keyword
      end
      str += format(tagW, attrStr, textW)
      str += "\n"
    end

    unless @seeAlso.empty?
      str += "See also:    "
      alsoStr = ''
      @seeAlso.each do |also|
        unless alsoStr.empty?
          alsoStr += ', '
        end
        alsoStr += also.keyword
      end
      str += format(tagW, alsoStr, textW)
      str += "\n"
    end

#    str += "Rule:    #{@rule.name}\n" if @rule
#    str += "Pattern: #{@pattern.tokens.join(' ')}\n" if @pattern
    str
  end

  def format(indent, str, width)
    out = ''
    width - indent
    linePos = 0
    word = ''
    i = 0
    indentBuf = ''
    while i < str.length
      if linePos >= width
        out += "\n" + ' ' * indent
        linePos = 0
        unless word.empty?
          i -= word.length - 1
          word = ''
          next
        end
      end
      if str[i] == ?\n
        out += word + "\n"
        indentBuf = ' ' * indent
        word = ''
        linePos = 0
      elsif str[i] == ?\s
        unless indentBuf.empty?
          out += indentBuf
          indentBuf = ''
        end
        out += word
        word = ' '
        linePos += 1
      else
        word << str[i]
        linePos += 1
      end
      i += 1
    end
    unless word.empty? || indentBuf.empty?
      out += indentBuf
    end
    out += word
  end

end

