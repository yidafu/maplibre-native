/**
 * Style Model Unit Tests
 *
 * Tests for pure ArkTS style model classes:
 * TransitionOptions, GeoJsonOptionsBuilder, PropertyValue, PropertyFactory, Expression
 *
 * Note: Light and concrete layer types (FillLayer, etc.) depend on NAPI
 * imports from libmaplibre.so and require mocked NAPI or ohosTest.
 * They are excluded from Layer 1 and will be tested in Layer 2.
 */
import { describe, it, expect } from '@ohos/hypium';
import { TransitionOptions } from '../main/ets/maps/style/layers/TransitionOptions';
import { GeoJsonOptionsBuilder } from '../main/ets/maps/style/sources/GeoJsonOptions';
import { PropertyValue } from '../main/ets/maps/style/layers/PropertyValue';
import { PaintPropertyValue } from '../main/ets/maps/style/layers/PaintPropertyValue';
import { LayoutPropertyValue } from '../main/ets/maps/style/layers/LayoutPropertyValue';
import { Expression, ExpressionLiteral } from '../main/ets/maps/style/expressions/Expression';
import { ITransitionOptions } from '../main/ets/maps/style/layers/TransitionOptions';

export default function StyleModelUnitTest() {
  // ==================== TransitionOptions ====================
  describe('TransitionOptions', () => {
    it('should create with default values', 0, () => {
      const options = new TransitionOptions();
      expect(options.duration).assertEqual(300);
      expect(options.delay).assertEqual(0);
    });

    it('should create with custom duration and delay', 0, () => {
      const options = new TransitionOptions(500, 100);
      expect(options.duration).assertEqual(500);
      expect(options.delay).assertEqual(100);
    });

    it('should clamp negative duration to zero', 0, () => {
      const options = new TransitionOptions(-100, -50);
      expect(options.duration).assertEqual(0);
      expect(options.delay).assertEqual(0);
    });

    it('static create should return equivalent instance', 0, () => {
      const options = TransitionOptions.create(400, 50);
      expect(options.duration).assertEqual(400);
      expect(options.delay).assertEqual(50);
    });

    it('fromObject should restore from interface', 0, () => {
      const obj: ITransitionOptions = { duration: 600, delay: 200 };
      const options = TransitionOptions.fromObject(obj);
      expect(options.duration).assertEqual(600);
      expect(options.delay).assertEqual(200);
    });

    it('fromObject should handle partial interface with defaults', 0, () => {
      const options = TransitionOptions.fromObject({});
      expect(options.duration).assertEqual(300);
      expect(options.delay).assertEqual(0);
    });

    it('fromObject should handle undefined fields', 0, () => {
      const options = TransitionOptions.fromObject({ duration: undefined, delay: undefined });
      expect(options.duration).assertEqual(300);
      expect(options.delay).assertEqual(0);
    });

    it('toObject should return plain object', 0, () => {
      const options = new TransitionOptions(500, 100);
      const obj = options.toObject();
      expect(obj.duration).assertEqual(500);
      expect(obj.delay).assertEqual(100);
    });
  });

  // ==================== PropertyValue ====================
  describe('PropertyValue', () => {
    it('should create with name and value', 0, () => {
      const prop = new PropertyValue<number>('opacity', 0.5);
      expect(prop.getName()).assertEqual('opacity');
      expect(prop.getValue()).assertEqual(0.5);
    });

    it('isValue should return true for constant value', 0, () => {
      const prop = new PropertyValue<string>('color', '#ff0000');
      expect(prop.isValue()).assertTrue();
      expect(prop.isExpression()).assertFalse();
    });

    it('isExpression should return true when expression is set', 0, () => {
      const expr = Expression.literal(1.0);
      const prop = new PropertyValue<number>('opacity', null, expr);
      expect(prop.isValue()).assertFalse();
      expect(prop.isExpression()).assertTrue();
    });

    it('isValue and isExpression should be false for null value', 0, () => {
      const prop = new PropertyValue<number>('opacity');
      expect(prop.isValue()).assertFalse();
      expect(prop.isExpression()).assertFalse();
    });

    it('toJSON should serialize constant value', 0, () => {
      const prop = new PropertyValue<number>('opacity', 0.5);
      const json = prop.toJSON();
      expect(json['name']).assertEqual('opacity');
      expect(json['value']).assertEqual(0.5);
    });

    it('toString should format correctly', 0, () => {
      const prop = new PropertyValue<number>('opacity', 0.5);
      expect(prop.toString()).assertEqual('PropertyValue(opacity=0.5)');
    });

    it('getExpression should return null for constant value', 0, () => {
      const prop = new PropertyValue<number>('opacity', 0.5);
      expect(prop.getExpression()).assertNull();
    });

    it('getExpression should return expression when set', 0, () => {
      const expr = Expression.literal(1.0);
      const prop = new PropertyValue<number>('opacity', null, expr);
      expect(prop.getExpression() !== null).assertTrue();
      if (prop.getExpression() !== null) {
        expect(prop.getExpression()!.isValue()).assertTrue();
      }
    });
  });

  // ==================== PaintPropertyValue ====================
  describe('PaintPropertyValue', () => {
    it('should create with name and value', 0, () => {
      const prop = PaintPropertyValue.value('fill-color', '#ff0000');
      expect(prop.getName()).assertEqual('fill-color');
      expect(prop.getValue()).assertEqual('#ff0000');
    });

    it('static expression factory should create expression-backed', 0, () => {
      const expr: Expression<number> = Expression.literal(0.5);
      const prop = PaintPropertyValue.expression<number>('fill-opacity', expr);
      expect(prop.isExpression()).assertTrue();
    });
  });

  // ==================== LayoutPropertyValue ====================
  describe('LayoutPropertyValue', () => {
    it('should create with name and value', 0, () => {
      const prop = LayoutPropertyValue.value('visibility', 'visible');
      expect(prop.getName()).assertEqual('visibility');
      expect(prop.getValue()).assertEqual('visible');
    });

    it('static expression factory should create expression-backed', 0, () => {
      const expr: Expression<string> = Expression.literal('none');
      const prop = LayoutPropertyValue.expression<string>('visibility', expr);
      expect(prop.isExpression()).assertTrue();
    });
  });

  // ==================== GeoJsonOptionsBuilder ====================
  describe('GeoJsonOptionsBuilder', () => {
    it('should build with default values', 0, () => {
      const builder = new GeoJsonOptionsBuilder();
      const options = builder.build();
      expect(options !== null).assertTrue();
      if (options !== null) {
        expect(options.cluster === undefined || options.cluster === false).assertTrue();
      }
    });

    it('should set cluster options via builder chain', 0, () => {
      const options = new GeoJsonOptionsBuilder()
        .withCluster(true)
        .withClusterRadius(50)
        .withClusterMaxZoom(14)
        .withClusterMinPoints(2)
        .withMaxZoom(16)
        .withMinZoom(0)
        .build();

      expect(options.cluster).assertTrue();
      expect(options.clusterRadius).assertEqual(50);
      expect(options.clusterMaxZoom).assertEqual(14);
      expect(options.clusterMinPoints).assertEqual(2);
      expect(options.maxzoom).assertEqual(16);
      expect(options.minzoom).assertEqual(0);
    });

    it('should set data options via builder chain', 0, () => {
      const options = new GeoJsonOptionsBuilder()
        .withTolerance(0.5)
        .withBuffer(128)
        .withGenerateId(true)
        .withLineMetrics(true)
        .build();

      expect(options.tolerance).assertEqual(0.5);
      expect(options.buffer).assertEqual(128);
      expect(options.generateId).assertTrue();
      expect(options.lineMetrics).assertTrue();
    });

    it('should set promoteId option', 0, () => {
      const options = new GeoJsonOptionsBuilder()
        .withPromoteId('custom_id')
        .build();

      expect(options.promoteId).assertEqual('custom_id');
    });

    it('should allow chaining all methods', 0, () => {
      const builder = new GeoJsonOptionsBuilder();
      // Verify chain returns builder
      const result = builder.withCluster(true).withBuffer(64).withTolerance(0.4);
      expect(result === builder).assertTrue();
    });
  });

  // ==================== Expression ====================
  describe('Expression', () => {
    it('should create with operator and args', 0, () => {
      const expr = new Expression('*', Expression.literal(2), Expression.literal(3));
      expect(expr.getOperator()).assertEqual('*');
    });

    it('getArguments should return the argument list', 0, () => {
      const arg1 = Expression.literal(2);
      const arg2 = Expression.literal(3);
      const expr = new Expression('+', arg1, arg2);
      const args = expr.getArguments();
      expect(args !== null).assertTrue();
      if (args !== null) {
        expect(args.length).assertEqual(2);
      }
    });

    it('getArguments should return null for leaf expression', 0, () => {
      const expr = Expression.literal(42);
      expect(expr.getArguments()).assertNull();
    });

    it('literal should create leaf expression', 0, () => {
      const expr = Expression.literal(42);
      expect(expr.isValue()).assertTrue();
      expect(expr.getOperator()).assertEqual('literal');
    });

    it('literal should handle strings', 0, () => {
      const expr = Expression.literal('hello');
      expect(expr.isValue()).assertTrue();
    });

    it('literal should handle booleans', 0, () => {
      const expr = Expression.literal(true);
      expect(expr.isValue()).assertTrue();
    });

    it('toArray should serialize correctly', 0, () => {
      const expr = Expression.literal(42);
      const arr = expr.toArray();
      expect(arr[0]).assertEqual('literal');
      expect(arr[1]).assertEqual(42);
    });

    it('toArray should handle nested expressions', 0, () => {
      const expr = new Expression('+', Expression.literal(1), Expression.literal(2));
      const arr = expr.toArray();
      expect(arr[0]).assertEqual('+');
    });

    it('equals should detect identical expressions', 0, () => {
      const a = Expression.literal(42);
      const b = Expression.literal(42);
      expect(a.equals(b)).assertTrue();
    });

    it('equals should detect different expressions', 0, () => {
      const a = Expression.literal(42);
      const b = Expression.literal(43);
      expect(a.equals(b)).assertFalse();
    });

    it('equals should handle null', 0, () => {
      const expr = Expression.literal(42);
      expect(expr.equals(null)).assertFalse();
    });

    it('get should create get expression', 0, () => {
      const expr = Expression.get('name');
      expect(expr.getOperator()).assertEqual('get');
    });

    it('has should create has expression', 0, () => {
      const expr = Expression.has('name');
      expect(expr.getOperator()).assertEqual('has');
    });

    it('zoom should create zoom expression', 0, () => {
      const expr = Expression.zoom();
      expect(expr.getOperator()).assertEqual('zoom');
    });

    it('eq/neq should create comparison expressions', 0, () => {
      expect(Expression.eq(Expression.literal(1), Expression.literal(1)).getOperator()).assertEqual('==');
      expect(Expression.neq(Expression.literal(1), Expression.literal(2)).getOperator()).assertEqual('!=');
    });

    it('gt/lt/gte/lte should create comparison expressions', 0, () => {
      expect(Expression.gt(Expression.literal(2), Expression.literal(1)).getOperator()).assertEqual('>');
      expect(Expression.lt(Expression.literal(1), Expression.literal(2)).getOperator()).assertEqual('<');
      expect(Expression.gte(Expression.literal(2), Expression.literal(1)).getOperator()).assertEqual('>=');
      expect(Expression.lte(Expression.literal(1), Expression.literal(2)).getOperator()).assertEqual('<=');
    });

    it('should create arithmetic expressions', 0, () => {
      expect(Expression.add(Expression.literal(1), Expression.literal(2)).getOperator()).assertEqual('+');
      expect(Expression.subtract(Expression.literal(5), Expression.literal(3)).getOperator()).assertEqual('-');
      expect(Expression.multiply(Expression.literal(2), Expression.literal(3)).getOperator()).assertEqual('*');
      expect(Expression.divide(Expression.literal(6), Expression.literal(2)).getOperator()).assertEqual('/');
    });

    it('should create logical expressions', 0, () => {
      expect(Expression.all(Expression.literal(true)).getOperator()).assertEqual('all');
      expect(Expression.any(Expression.literal(false)).getOperator()).assertEqual('any');
      expect(Expression.not(Expression.literal(true)).getOperator()).assertEqual('!');
    });

    it('should create conditional expressions', 0, () => {
      expect(Expression.switchCase(Expression.literal(true), Expression.literal('yes'), Expression.literal('no')).getOperator()).assertEqual('case');
      expect(Expression.coalesce(Expression.literal('a'), Expression.literal('b')).getOperator()).assertEqual('coalesce');
    });

    it('should create step expression', 0, () => {
      const defaultVal: Expression<Object> = new ExpressionLiteral<Object>(0);
      const stopPair = Expression.stop(10, Expression.literal(1));
      const expr = Expression.step(Expression.zoom(), defaultVal, stopPair[0], stopPair[1]);
      expect(expr.getOperator()).assertEqual('step');
    });

    it('should create interpolate expression', 0, () => {
      const stop1 = Expression.stop(0, Expression.literal(0));
      const stop2 = Expression.stop(10, Expression.literal(1));
      const expr = Expression.interpolate(
        Expression.linear(),
        Expression.zoom(),
        stop1[0], stop1[1],
        stop2[0], stop2[1]
      );
      expect(expr.getOperator()).assertEqual('interpolate');
    });

    it('toString should return expression string', 0, () => {
      const expr = Expression.literal(42);
      expect(expr.toString()).assertContain('literal');
    });

    it('should handle empty operator exception', 0, () => {
      const expr = new Expression('');
      expect(() => {
        expr.toArray();
      }).assertThrowError(Error);
    });
  });
}